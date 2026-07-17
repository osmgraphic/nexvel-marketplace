// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Initializable} from "@openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import {AccessControlUpgradeable} from "@openzeppelin-contracts/contracts/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-contracts/contracts/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-contracts/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IMarketplaceAddressRegistry} from "../nft/interfaces/IMarketplaceAddressRegistry.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title NexvelSecurityUpgradeable
 * @notice Centralized security, role, and emergency-control layer for Nexvel protocol
 * @dev This abstract contract is inherited by all core Nexvel contracts
 *      (NFTs, Marketplace, Launchpad, Factory).
 *
 *      Responsibilities:
 *      - Unified role-based access control
 *      - Global + local pause mechanisms
 *      - Emergency asset recovery
 *
 *      This contract intentionally contains NO business logic.
 */
abstract contract NexvelSecurityUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Protocol administrator with full control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Authorized marketplace contracts
    bytes32 public constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");

    /// @notice Trusted operator for system-level actions
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @notice Authorized upgrade controller (UUPS / proxy upgrades)
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @notice Approved NFT creators
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    /// @notice Authorized launchpad contracts
    bytes32 public constant LAUNCHPAD_ROLE = keccak256("LAUNCHPAD_ROLE");

    IMarketplaceAddressRegistry public registry;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Protocol-wide emergency pause flag
     * @dev Independent from OpenZeppelin Pausable.
     *      Child contracts must explicitly check this flag.
     */
    bool public globalPaused;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted whenever global pause state changes
    event GlobalPaused(bool status);

    /*//////////////////////////////////////////////////////////////
                              INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes core security roles for Nexvel protocol
     * @dev Must be called exactly once by inheriting initializer.
     * @param admin_       Protocol admin (highest authority)
     * @param operator_    Trusted operator for system operations
     * @param creators_    Initial creator whitelist
     */
    function __NexvelSecurity_init(address admin_, address operator_, address registry_, address[] calldata creators_)
        internal
        onlyInitializing
    {
        registry = IMarketplaceAddressRegistry(registry_);
        require(admin_ != address(0), "Admin zero");

        require(operator_ != address(0), "Operator zero");

        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        // Core authority roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(ADMIN_ROLE, admin_);
        _grantRole(UPGRADER_ROLE, admin_);

        // System-level roles

        _grantRole(OPERATOR_ROLE, operator_);

        // Role hierarchy configuration
        _setRoleAdmin(OPERATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MARKETPLACE_ROLE, ADMIN_ROLE);
        _setRoleAdmin(CREATOR_ROLE, ADMIN_ROLE);
        _setRoleAdmin(LAUNCHPAD_ROLE, ADMIN_ROLE);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);

        // Initial creator whitelist
        for (uint256 i = 0; i < creators_.length; i++) {
            require(creators_[i] != address(0), "Creator zero");
            _grantRole(CREATOR_ROLE, creators_[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    function _onlyMarketplace() internal view {
        require(msg.sender == registry.marketplace(), "Not marketplace");
    }

    /// @dev Restricts function access to marketplace contracts
    modifier onlyMarketplace() {
        _onlyMarketplace();
        _;
    }

    function _onlyLaunchpad() internal view {
        require(msg.sender == registry.launchpad(), "Not launchpad");
    }

    /// @dev Restricts function access to launchpad contracts
    modifier onlyLaunchpad() {
        _onlyLaunchpad();
        _;
    }

    /// @dev Restricts function access to protocol admins
    modifier onlyAdmin() {
        _checkRole(ADMIN_ROLE, msg.sender);
        _;
    }

    /// @dev Restricts function access to trusted operators
    modifier onlyOperator() {
        _checkRole(OPERATOR_ROLE, msg.sender);
        _;
    }

    /// @dev Restricts function access to approved creators
    modifier onlyCreator() {
        _checkRole(CREATOR_ROLE, msg.sender);
        _;
    }

    /**
     * @dev Global protocol pause guard.
     *      Must be used explicitly by child contracts.
     */
    function _whenGlobalNotPaused() internal view {
        require(!globalPaused, "Protocol paused");
    }

    modifier whenGlobalNotPaused() {
        _whenGlobalNotPaused();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            PAUSE CONTROLS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enable or disable global protocol pause
     * @dev Does NOT automatically affect inheriting contracts.
     */
    function setGlobalPause(bool status) external onlyAdmin {
        globalPaused = status;
        emit GlobalPaused(status);
    }

    /// @notice Pauses the current contract
    function pause() external onlyAdmin {
        _pause();
    }

    /// @notice Unpauses the current contract
    function unpause() external onlyAdmin {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emergency ERC20 recovery
     * @dev Intended strictly for paused-state incident response
     */
    function emergencyWithdrawERC20(address token, address to, uint256 amount) external onlyAdmin whenPaused {
        require(to != address(0), "Zero recipient");
        IERC20(token).safeTransfer(to, amount);
    }

    /**
     * @notice Emergency ERC721 recovery
     */
    function emergencyWithdrawERC721(address nft, uint256 tokenId, address to) external onlyAdmin whenPaused {
        require(to != address(0), "Zero recipient");
        IERC721(nft).safeTransferFrom(address(this), to, tokenId);
    }

    /**
     * @notice Emergency ERC1155 recovery
     */
    function emergencyWithdrawERC1155(address nft, uint256 tokenId, uint256 amount, address to)
        external
        onlyAdmin
        whenPaused
    {
        require(to != address(0), "Zero recipient");
        IERC1155(nft).safeTransferFrom(address(this), to, tokenId, amount, "");
    }

    /**
     * @notice Emergency ETH recovery
     */
    function emergencyWithdrawEth(address to) external onlyAdmin whenPaused {
        require(to != address(0), "Zero recipient");
        (bool success,) = to.call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    /*//////////////////////////////////////////////////////////////
                        ROLE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enable or disable a launchpad contract
     * @dev Allows controlled onboarding or removal of launchpads
     */
    function setLaunchpad(address launchpad, bool enabled) external onlyAdmin {
        require(launchpad != address(0), "Zero address");

        if (enabled) {
            _grantRole(LAUNCHPAD_ROLE, launchpad);
        } else {
            _revokeRole(LAUNCHPAD_ROLE, launchpad);
        }
    }
}
