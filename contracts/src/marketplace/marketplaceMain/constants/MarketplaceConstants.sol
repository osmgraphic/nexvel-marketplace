// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Nexvel Marketplace Constants
/// @author Nexvel
/// @notice Global constants shared across all marketplace modules.
/// @dev These values are compile-time constants and do not consume storage.
abstract contract MarketplaceConstants {
    /*//////////////////////////////////////////////////////////////
                            BASIS POINTS
    //////////////////////////////////////////////////////////////*/

    /// @dev 100% = 10,000 basis points
    uint256 internal constant BPS = 10_000;

    /// @dev Maximum marketplace fee = 10%
    uint96 internal constant MAX_MARKETPLACE_FEE_BPS = 1_000;

    /*//////////////////////////////////////////////////////////////
                            ADDRESS
    //////////////////////////////////////////////////////////////*/

    /// @dev Native ETH payment
    address internal constant NATIVE_TOKEN = address(0);

    /*//////////////////////////////////////////////////////////////
                        AUCTION CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @dev Minimum auction duration
    uint256 internal constant MIN_AUCTION_DURATION = 1 hours;

    /// @dev Maximum auction duration
    uint256 internal constant MAX_AUCTION_DURATION = 30 days;

    /// @dev Anti-sniping window
    uint256 internal constant AUCTION_EXTENSION_WINDOW = 10 minutes;

    /// @dev Extension added if bid arrives within extension window
    uint256 internal constant AUCTION_EXTENSION_DURATION = 10 minutes;

    /// @dev Minimum bid increment = 2.5%
    uint256 internal constant MIN_BID_INCREMENT_BPS = 250;

    /*//////////////////////////////////////////////////////////////
                        MARKETPLACE LIMITS
    //////////////////////////////////////////////////////////////*/

    /// @dev Maximum royalty allowed (50%)
    uint96 internal constant MAX_ROYALTY_BPS = 5_000;

    /*//////////////////////////////////////////////////////////////
                            SIGNATURES
    //////////////////////////////////////////////////////////////*/

    string internal constant EIP712_NAME = "Nexvel Marketplace";

    string internal constant EIP712_VERSION = "1";

    /*//////////////////////////////////////////////////////////////
                            VERSION
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MARKETPLACE_VERSION = 4;

    /*//////////////////////////////////////////////////////////////
                            STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    uint256[50] private __gap;
}