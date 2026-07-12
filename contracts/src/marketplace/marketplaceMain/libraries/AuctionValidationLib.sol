// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";
import {MarketplaceErrors} from "../errors/MarketplaceErrors.sol";
import {ValidationLib} from "./ValidationLib.sol";

/// @title AuctionValidationLib
/// @author Nexvel
/// @notice Validation library for marketplace auctions.
/// @dev
/// Handles all auction lifecycle validations.
///
/// Responsibilities:
/// - Auction creation
/// - Bid validation
/// - Auction cancellation
/// - Auction settlement
///
/// This library never:
/// - Reads contract storage
/// - Performs external calls
/// - Transfers assets
/// - Emits events
library AuctionValidationLib {
    /*//////////////////////////////////////////////////////////////
                        CREATE AUCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates auction creation.
    /// @param params Auction creation parameters.
    function validateCreateAuction(
        MarketplaceTypes.CreateAuctionParams memory params
    ) internal view {
        ValidationLib.validateAddress(params.nft);

        ValidationLib.validatePrice(
            params.minimumPrice
        );

        ValidationLib.validateQuantity(
            params.quantity
        );

        ValidationLib.validateAmount(
            params.duration
        );

        // ERC721 must always have quantity = 1.
        // Marketplace721 should always pass quantity = 1.
    }

    /*//////////////////////////////////////////////////////////////
                            BID
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates bid placement.
    /// @param auction Auction information.
    /// @param params Bid parameters.
    /// @param bidder Bidder address.
    function validateBid(
        MarketplaceTypes.Auction memory auction,
        MarketplaceTypes.BidParams memory params,
        address bidder
    ) internal view {
        if (auction.seller == address(0)) {
            revert MarketplaceErrors.AuctionNotFound();
        }

        ValidationLib.validateStartTime(
            auction.startTime
        );

        ValidationLib.validateEndTime(
            auction.endTime
        );

        ValidationLib.validateBidder(
            auction.seller,
            bidder
        );

        ValidationLib.validateExpectedHighestBid(
            params.expectedHighestBid,
            auction.highestBid
        );

        ValidationLib.validateAmount(
            params.amount
        );

        if (auction.highestBid == 0) {
            if (params.amount < auction.minimumPrice) {
                revert MarketplaceErrors.BidTooLow();
            }
        } else {
            ValidationLib.validateBidAmount(
                params.amount,
                auction.highestBid
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL AUCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates auction cancellation.
    /// @param auction Auction information.
    /// @param sender Transaction sender.
    function validateCancelAuction(
        MarketplaceTypes.Auction memory auction,
        address sender
    ) internal pure {
        if (auction.seller == address(0)) {
            revert MarketplaceErrors.AuctionNotFound();
        }

        if (auction.seller != sender) {
            revert MarketplaceErrors.NotAuctionOwner();
        }

        if (auction.highestBidder != address(0)) {
            revert MarketplaceErrors.AuctionAlreadyHasBid();
        }
    }

    /*//////////////////////////////////////////////////////////////
                    SETTLEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates auction settlement.
    /// @param auction Auction information.
    function validateSettlement(
        MarketplaceTypes.Auction memory auction
    ) internal view {
        if (auction.seller == address(0)) {
            revert MarketplaceErrors.AuctionNotFound();
        }

        ValidationLib.validateAuctionEnded(
            auction.endTime
        );

        if (auction.highestBidder == address(0)) {
            revert MarketplaceErrors.NoWinningBid();
        }

        ValidationLib.validateAmount(
            auction.highestBid
        );
    }

    /*//////////////////////////////////////////////////////////////
                        ACTIVE AUCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates an active auction.
    /// @param auction Auction information.
    function validateActiveAuction(
        MarketplaceTypes.Auction memory auction
    ) internal view {
        if (auction.seller == address(0)) {
            revert MarketplaceErrors.AuctionNotFound();
        }

        ValidationLib.validateStartTime(
            auction.startTime
        );

        ValidationLib.validateEndTime(
            auction.endTime
        );

        ValidationLib.validateQuantity(
            auction.quantity
        );

        ValidationLib.validatePrice(
            auction.minimumPrice
        );
    }

    /*//////////////////////////////////////////////////////////////
                        ERC721 RULE
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates ERC721 auction quantity.
    /// @param auction Auction information.
    function validateERC721Auction(
        MarketplaceTypes.Auction memory auction
    ) internal pure {
        if (
            auction.assetType ==
            MarketplaceTypes.AssetType.ERC721
        ) {
            ValidationLib.validateERC721Quantity(
                auction.quantity
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                        WINNER
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates auction winner.
    /// @param auction Auction information.
    /// @param winner Winner address.
    function validateWinner(
        MarketplaceTypes.Auction memory auction,
        address winner
    ) internal pure {
        if (winner != auction.highestBidder) {
            revert MarketplaceErrors.InvalidWinner();
        }
    }
}