// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceErrors} from "../errors/MarketplaceErrors.sol";

/// @title ValidationLib
/// @author Nexvel
/// @notice Shared primitive validation library used across the Nexvel Marketplace.
/// @dev
/// This library is intentionally stateless.
/// It performs only primitive validations and never:
/// - reads contract storage
/// - performs external calls
/// - transfers ETH/ERC20/NFT
/// - emits events
library ValidationLib {
    /*//////////////////////////////////////////////////////////////
                            ADDRESS
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates a non-zero address.
    /// @param account Address to validate.
    function validateAddress(address account) internal pure {
        if (account == address(0)) {
            revert MarketplaceErrors.InvalidAddress(account);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            PRICE
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates a non-zero price.
    /// @param price Price value.
    function validatePrice(uint256 price) internal pure {
        if (price == 0) {
            revert MarketplaceErrors.InvalidPrice(price);
        }
    }

    /*//////////////////////////////////////////////////////////////
                            QUANTITY
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates a non-zero quantity.
    /// @param quantity Quantity value.
    function validateQuantity(uint256 quantity) internal pure {
        if (quantity == 0) {
            revert MarketplaceErrors.InvalidQuantity();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            DEADLINE
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates a deadline timestamp.
    /// @dev Reverts if the deadline has already passed.
    /// @param deadline Deadline timestamp.
    function validateDeadline(uint64 deadline) internal view {
        if (deadline != 0 && block.timestamp > deadline) {
            revert MarketplaceErrors.ValidationFailed();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            EXPIRY
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates a listing expiry timestamp.
    /// @param expiry Expiry timestamp.
    function validateExpiry(uint64 expiry) internal view {
        if (expiry != 0 && block.timestamp > expiry) {
            revert MarketplaceErrors.ListingExpired();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            TIME
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates auction start time.
    /// @param startTime Auction start timestamp.
    function validateStartTime(uint64 startTime) internal view {
        if (block.timestamp < startTime) {
            revert MarketplaceErrors.AuctionNotStarted();
        }
    }

    /// @notice Validates auction end time.
    /// @param endTime Auction end timestamp.
    function validateEndTime(uint64 endTime) internal view {
        if (block.timestamp >= endTime) {
            revert MarketplaceErrors.AuctionEnded();
        }
    }

    /// @notice Validates that an auction has ended.
    /// @param endTime Auction end timestamp.
    function validateAuctionEnded(uint64 endTime) internal view {
        if (block.timestamp < endTime) {
            revert MarketplaceErrors.AuctionNotEnded();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            AMOUNT
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates a non-zero amount.
    /// @param amount Amount to validate.
    function validateAmount(uint256 amount) internal pure {
        if (amount == 0) {
            revert MarketplaceErrors.InvalidAmount();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        PERCENTAGE / BPS
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates basis points.
    /// @param bps Basis points.
    /// @param maxBps Maximum allowed basis points.
    function validateBasisPoints(uint96 bps, uint96 maxBps) internal pure {
        if (bps > maxBps) {
            revert MarketplaceErrors.InvalidMarketplaceFee();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        TRADE VALUE
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates maximum trade value.
    /// @param tradeValue Trade value.
    function validateTradeValue(uint256 tradeValue) internal pure {
        if (tradeValue == 0) {
            revert MarketplaceErrors.InvalidTradeValue();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        PAYMENT TOKEN
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates payment token configuration.
    /// @param supported Whether payment token is supported.
    /// @param enabled Whether payment token is enabled.
    function validatePaymentToken(bool supported, bool enabled) internal pure {
        if (!supported) {
            revert MarketplaceErrors.UnsupportedPaymentToken();
        }

        if (!enabled) {
            revert MarketplaceErrors.PaymentTokenDisabled();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        COLLECTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates collection configuration.
    /// @param supported Whether collection is supported.
    /// @param tradingEnabled Whether trading is enabled.
    function validateCollection(bool supported, bool tradingEnabled) internal pure {
        if (!supported) {
            revert MarketplaceErrors.UnsupportedCollection();
        }

        if (!tradingEnabled) {
            revert MarketplaceErrors.CollectionTradingDisabled();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        QUANTITY RULES
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates ERC721 quantity.
    /// @param quantity Asset quantity.
    function validateERC721Quantity(uint256 quantity) internal pure {
        if (quantity != 1) {
            revert MarketplaceErrors.InvalidQuantity();
        }
    }

    /// @notice Validates ERC1155 purchase quantity.
    /// @param requested Requested quantity.
    /// @param available Available quantity.
    function validateAvailableQuantity(uint256 requested, uint256 available) internal pure {
        if (requested == 0) {
            revert MarketplaceErrors.InvalidQuantity();
        }

        if (requested > available) {
            revert MarketplaceErrors.InsufficientQuantity();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        PRICE PROTECTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates optimistic price protection.
    /// @param expected Expected price.
    /// @param current Current on-chain price.
    function validateExpectedPrice(uint256 expected, uint256 current) internal pure {
        if (expected != current) {
            revert MarketplaceErrors.PriceChanged();
        }
    }

    /// @notice Validates optimistic highest bid protection.
    /// @param expected Expected highest bid.
    /// @param current Current highest bid.
    function validateExpectedHighestBid(uint256 expected, uint256 current) internal pure {
        if (expected != current) {
            revert MarketplaceErrors.BidStateChanged();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            BID
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates bid amount.
    /// @param amount Bid amount.
    /// @param minimum Minimum required bid.
    function validateBidAmount(uint256 amount, uint256 minimum) internal pure {
        if (amount <= minimum) {
            revert MarketplaceErrors.BidTooLow();
        }
    }

    /// @notice Prevents seller from bidding.
    /// @param seller Seller address.
    /// @param bidder Bidder address.
    function validateBidder(address seller, address bidder) internal pure {
        if (seller == bidder) {
            revert MarketplaceErrors.SellerCannotBid();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            GENERIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates that a boolean condition is true.
    /// @param condition Condition to validate.
    function validateCondition(bool condition) internal pure {
        if (!condition) {
            revert MarketplaceErrors.ValidationFailed();
        }
    }
}
