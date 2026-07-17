// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IMarketplaceRegistry
/// @author Nexvel
/// @notice Central registry interface for the Nexvel Marketplace Protocol.
/// @dev
/// The Registry is the single source of truth for:
/// - Marketplace module addresses
/// - Treasury configuration
/// - Marketplace fee configuration
/// - Global protocol pause state
/// - Supported NFT collections
/// - Supported payment tokens
///
/// IMPORTANT:
/// - Keep this interface backward compatible.
/// - Never remove or change existing function signatures.
/// - Only append new functions in future versions.
interface IMarketplaceRegistry {
    /*//////////////////////////////////////////////////////////////
                                MODULES
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the ERC721 marketplace contract.
    function marketplace721() external view returns (address);

    /// @notice Returns the ERC1155 marketplace contract.
    function marketplace1155() external view returns (address);

    /// @notice Returns the payment module contract.
    function marketplacePayment() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the protocol treasury.
    function treasury() external view returns (address);

    /// @notice Returns the marketplace fee in basis points.
    function marketplaceFeeBps() external view returns (uint96);

    /// @notice Returns the maximum allowed trade value.
    function maxTradeValue() external view returns (uint256);

    /// @notice Returns true if the protocol is globally paused.
    function globalPaused() external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                        SUPPORTED ASSETS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether an NFT collection is supported.
    /// @param collection NFT collection address.
    function isCollectionSupported(address collection) external view returns (bool);

    /// @notice Returns whether a payment token is supported.
    /// @param token ERC20 payment token.
    function isPaymentTokenSupported(address token) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                            MODULE VALIDATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns true if the address is a registered protocol module.
    /// @param module Module address.
    function isModule(address module) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                                VERSION
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the registry version.
    function version() external view returns (uint256);
}
