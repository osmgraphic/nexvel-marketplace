// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";
import {MarketplaceConstants} from "../libraries/MarketplaceConstants.sol";
import {MarketplaceErrors} from "../errors/MarketplaceErrors.sol";
import {IMarketplaceRegistry} from "../interfaces/IMarketplaceRegistry.sol";
import {MarketplaceEvents} from "../events/MarketplaceEvents.sol";

/// @title MarketplaceRegistry
/// @author Nexvel
/// @notice Central registry for the Nexvel Marketplace Protocol.
/// @dev
/// Responsibilities:
/// - Module Registry
/// - Marketplace Configuration
/// - Collection Registry
/// - Payment Token Registry
///
/// This contract MUST NOT:
/// - Execute marketplace logic
/// - Handle payments
/// - Transfer NFTs
/// - Verify signatures
///
/// Upgradeability:
/// - UUPS Proxy
///
/// Access Control:
/// - AccessControlUpgradeable
abstract contract MarketplaceRegistry is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IMarketplaceRegistry
{
    /*//////////////////////////////////////////////////////////////
                                ROLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant REGISTRY_ADMIN_ROLE = keccak256("REGISTRY_ADMIN_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Global marketplace configuration.
    MarketplaceTypes.MarketplaceConfig private _config;

    /// @dev Registered protocol modules.
    mapping(MarketplaceTypes.MarketplaceModule => MarketplaceTypes.ModuleInfo) private _modules;

    /// @dev Supported NFT collections.
    mapping(address => MarketplaceTypes.CollectionConfig) private _collections;

    /// @dev Supported payment tokens.
    mapping(address => MarketplaceTypes.PaymentTokenConfig) private _paymentTokens;

    /// @dev Registry version.
    uint64 private _version;

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the marketplace registry.
    /// @param admin Protocol administrator.
    /// @param treasuryAddress Treasury wallet.
    /// @param marketplaceFeeBps_ Marketplace fee in basis points.
    /// @param maxTradeValue_ Maximum trade value.
    function initialize(address admin, address treasuryAddress, uint96 marketplaceFeeBps_, uint256 maxTradeValue_)
        external
        initializer
    {
        if (admin == address(0)) {
            revert MarketplaceErrors.InvalidAddress(admin);
        }

        if (treasuryAddress == address(0)) {
            revert MarketplaceErrors.InvalidTreasury(treasuryAddress);
        }

        if (marketplaceFeeBps_ > MarketplaceConstants.MAX_MARKETPLACE_FEE_BPS) {
            revert MarketplaceErrors.InvalidMarketplaceFee();
        }

        if (maxTradeValue_ == 0) {
            revert MarketplaceErrors.InvalidTradeValue();
        }

        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRY_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);

        _setTreasury(treasuryAddress);
        _setMarketplaceFee(marketplaceFeeBps_);
        _setMaxTradeValue(maxTradeValue_);

        _config.globalPaused = false;

        _version = 1;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL CONFIG SETTERS
    //////////////////////////////////////////////////////////////*/

    function _setTreasury(address treasuryAddress) internal {
        if (treasuryAddress == address(0)) {
            revert MarketplaceErrors.InvalidTreasury(treasuryAddress);
        }

        _config.treasury = treasuryAddress;
    }

    function _setMarketplaceFee(uint96 marketplaceFeeBps_) internal {
        if (marketplaceFeeBps_ > MarketplaceConstants.MAX_MARKETPLACE_FEE_BPS) {
            revert MarketplaceErrors.InvalidMarketplaceFee();
        }

        _config.marketplaceFeeBps = marketplaceFeeBps_;
    }

    function _setMaxTradeValue(uint256 maxTradeValue_) internal {
        if (maxTradeValue_ == 0) {
            revert MarketplaceErrors.InvalidTradeValue();
        }

        _config.maxTradeValue = maxTradeValue_;
    }

    /*//////////////////////////////////////////////////////////////
                        UUPS AUTHORIZATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /*//////////////////////////////////////////////////////////////
                            STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    uint256[50] private _gap;

    /*//////////////////////////////////////////////////////////////
                            MODULE REGISTRY
    //////////////////////////////////////////////////////////////*/

    /// @notice Registers or updates a protocol module.
    /// @param moduleType Marketplace module type.
    /// @param moduleAddress Proxy address of the module.
    function setModule(MarketplaceTypes.MarketplaceModule moduleType, address moduleAddress)
        external
        onlyRole(REGISTRY_ADMIN_ROLE)
    {
        _setModule(moduleType, moduleAddress);
    }

    /// @notice Removes a registered protocol module.
    /// @param moduleType Marketplace module type.
    function removeModule(MarketplaceTypes.MarketplaceModule moduleType) external onlyRole(REGISTRY_ADMIN_ROLE) {
        _removeModule(moduleType);
    }

    /// @notice Returns the registered module address.
    /// @param moduleType Marketplace module type.
    function getModule(MarketplaceTypes.MarketplaceModule moduleType) public view returns (address) {
        return _getModule(moduleType);
    }

    /*//////////////////////////////////////////////////////////////
                        CONVENIENCE GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplaceRegistry
    function marketplace721() external view override returns (address) {
        return _getModule(MarketplaceTypes.MarketplaceModule.NFT721);
    }

    /// @inheritdoc IMarketplaceRegistry
    function marketplace1155() external view override returns (address) {
        return _getModule(MarketplaceTypes.MarketplaceModule.NFT1155);
    }

    /// @inheritdoc IMarketplaceRegistry
    function marketplacePayment() external view override returns (address) {
        return _getModule(MarketplaceTypes.MarketplaceModule.PAYMENT);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _setModule(MarketplaceTypes.MarketplaceModule moduleType, address moduleAddress) internal {
        if (moduleAddress == address(0)) {
            revert MarketplaceErrors.InvalidAddress(moduleAddress);
        }

        MarketplaceTypes.ModuleInfo storage moduleInfo = _modules[moduleType];

        if (moduleInfo.implementation == moduleAddress) {
            return;
        }

        moduleInfo.implementation = moduleAddress;
        moduleInfo.registeredAt = uint64(block.timestamp);

        emit MarketplaceEvents.ModuleRegistered(moduleType, moduleAddress);
    }

    function _removeModule(MarketplaceTypes.MarketplaceModule moduleType) internal {
        MarketplaceTypes.ModuleInfo storage moduleInfo = _modules[moduleType];

        if (moduleInfo.implementation == address(0)) {
            revert MarketplaceErrors.ModuleNotRegistered();
        }

        address previousModule = moduleInfo.implementation;

        delete _modules[moduleType];

        emit MarketplaceEvents.ModuleRemoved(moduleType, previousModule);
    }

    function _getModule(MarketplaceTypes.MarketplaceModule moduleType) internal view returns (address) {
        address module = _modules[moduleType].implementation;

        if (module == address(0)) {
            revert MarketplaceErrors.ModuleNotRegistered();
        }

        return module;
    }

    /*//////////////////////////////////////////////////////////////
                            CONFIG GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the complete marketplace configuration.
    function config() external view returns (MarketplaceTypes.MarketplaceConfig memory) {
        return _config;
    }

    /// @inheritdoc IMarketplaceRegistry
    function treasury() external view override returns (address) {
        return _config.treasury;
    }

    /// @inheritdoc IMarketplaceRegistry
    function marketplaceFeeBps() external view override returns (uint96) {
        return _config.marketplaceFeeBps;
    }

    /// @inheritdoc IMarketplaceRegistry
    function globalPaused() external view override returns (bool) {
        return _config.globalPaused;
    }

    /// @inheritdoc IMarketplaceRegistry
    function maxTradeValue() external view override returns (uint256) {
        return _config.maxTradeValue;
    }

    /// @notice Returns the current storage version.
    function version() external view returns (uint256) {
        return _version;
    }

    /*//////////////////////////////////////////////////////////////
                        COLLECTION GETTERS
    //////////////////////////////////////////////////////////////*/

    function collectionConfig(address collection) external view returns (MarketplaceTypes.CollectionConfig memory) {
        return _collections[collection];
    }

    /*//////////////////////////////////////////////////////////////
                    PAYMENT TOKEN GETTERS
    //////////////////////////////////////////////////////////////*/

    function paymentTokenConfig(address token) external view returns (MarketplaceTypes.PaymentTokenConfig memory) {
        return _paymentTokens[token];
    }

    /*//////////////////////////////////////////////////////////////
                        CONFIG ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setTreasury(address treasury_) external onlyRole(REGISTRY_ADMIN_ROLE) {
        _setTreasury(treasury_);
    }

    function setMarketplaceFee(uint96 fee) external onlyRole(REGISTRY_ADMIN_ROLE) {
        _setMarketplaceFee(fee);
    }

    function setGlobalPause(bool paused) external onlyRole(PAUSER_ROLE) {
        _setGlobalPause(paused);
    }

    function setTradeLimit(uint256 limit) external onlyRole(REGISTRY_ADMIN_ROLE) {
        _setTradeLimit(limit);
    }

    function updateMarketplaceConfig(address treasury_, uint96 fee, bool paused, uint256 tradeLimit)
        external
        onlyRole(REGISTRY_ADMIN_ROLE)
    {
        _setTreasury(treasury_);
        _setMarketplaceFee(fee);
        _setGlobalPause(paused);
        _setTradeLimit(tradeLimit);
    }

    /*//////////////////////////////////////////////////////////////
                    COLLECTION ADMIN
    //////////////////////////////////////////////////////////////*/

    function setCollectionConfig(address collection, MarketplaceTypes.CollectionConfig calldata config_)
        external
        onlyRole(REGISTRY_ADMIN_ROLE)
    {
        _setCollectionConfig(collection, config_);
    }

    /*//////////////////////////////////////////////////////////////
                PAYMENT TOKEN ADMIN
    //////////////////////////////////////////////////////////////*/

    function setPaymentTokenConfig(address token, MarketplaceTypes.PaymentTokenConfig calldata config_)
        external
        onlyRole(REGISTRY_ADMIN_ROLE)
    {
        _setPaymentTokenConfig(token, config_);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _setGlobalPause(bool paused) internal {
        if (_config.globalPaused == paused) {
            return;
        }

        _config.globalPaused = paused;

        emit MarketplaceEvents.GlobalPauseUpdated(paused);
    }

    function _setTradeLimit(uint256 limit) internal {
        if (limit == 0) {
            revert MarketplaceErrors.InvalidTradeValue();
        }

        if (_config.maxTradeValue == limit) {
            return;
        }

        _config.maxTradeValue = limit;

        emit MarketplaceEvents.TradeLimitUpdated(limit);
    }

    function _setCollectionConfig(address collection, MarketplaceTypes.CollectionConfig calldata config_) internal {
        if (collection == address(0)) {
            revert MarketplaceErrors.InvalidCollection();
        }

        MarketplaceTypes.CollectionConfig storage cfg = _collections[collection];

        cfg.supported = config_.supported;
        cfg.tradingEnabled = config_.tradingEnabled;
        cfg.lazyMintEnabled = config_.lazyMintEnabled;
        cfg.assetType = config_.assetType;
        cfg.royaltyBps = config_.royaltyBps;

        emit MarketplaceEvents.CollectionConfigUpdated(collection, config_.tradingEnabled, config_.royaltyBps);
    }

    function _setPaymentTokenConfig(address token, MarketplaceTypes.PaymentTokenConfig calldata config_) internal {
        if (token == address(0)) {
            revert MarketplaceErrors.InvalidPaymentToken();
        }

        MarketplaceTypes.PaymentTokenConfig storage cfg = _paymentTokens[token];

        cfg.supported = config_.supported;
        cfg.enabled = config_.enabled;
        cfg.decimals = config_.decimals;

        emit MarketplaceEvents.PaymentTokenRegistered(token, config_);
    }
}
