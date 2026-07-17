// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MarketplaceConstants
/// @author Nexvel
/// @notice Global compile-time constants shared across the Nexvel Marketplace.
/// @dev
/// This library contains only immutable compile-time constants.
/// It MUST NOT contain storage variables or functions.
library MarketplaceConstants {
    /*//////////////////////////////////////////////////////////////
                            BASIS POINTS
    //////////////////////////////////////////////////////////////*/

    /// @notice 100% = 10,000 basis points.
    uint256 public constant BPS = 10_000;

    /// @notice Maximum marketplace fee allowed (10%).
    uint96 public constant MAX_MARKETPLACE_FEE_BPS = 1_000;

    /*//////////////////////////////////////////////////////////////
                            ADDRESS
    //////////////////////////////////////////////////////////////*/

    /// @notice Native ETH payment token.
    address public constant NATIVE_TOKEN = address(0);

    /*//////////////////////////////////////////////////////////////
                    AUCTION CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Minimum auction duration.
    uint256 public constant MIN_AUCTION_DURATION = 1 hours;

    /// @notice Maximum auction duration.
    uint256 public constant MAX_AUCTION_DURATION = 30 days;

    /// @notice Anti-sniping window.
    uint256 public constant AUCTION_EXTENSION_WINDOW = 10 minutes;

    /// @notice Extension added when a valid bid arrives during the anti-sniping window.
    uint256 public constant AUCTION_EXTENSION_DURATION = 10 minutes;

    /// @notice Minimum bid increment (2.5% = 250 BPS).
    uint256 public constant MIN_BID_INCREMENT_BPS = 250;

    /*//////////////////////////////////////////////////////////////
                        MARKETPLACE LIMITS
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum royalty supported by the marketplace (50%).
    uint96 public constant MAX_ROYALTY_BPS = 5_000;

    /*//////////////////////////////////////////////////////////////
                            EIP-712
    //////////////////////////////////////////////////////////////*/

    /// @notice EIP-712 domain name.
    string public constant EIP712_NAME = "Nexvel Marketplace";

    /// @notice EIP-712 domain version.
    string public constant EIP712_VERSION = "1";

    string public constant MARKETPLACE_VERSION = "1.0.0";
}
