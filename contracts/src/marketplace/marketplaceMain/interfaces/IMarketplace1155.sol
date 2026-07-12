// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";
import {IMarketplaceBase} from "./IMarketplaceBase.sol";

/// @title IMarketplace1155
/// @author Nexvel
/// @notice Interface for the Nexvel ERC1155 Marketplace module.
/// @dev
/// Defines ERC1155-specific marketplace operations.
///
/// Inherited from IMarketplaceBase:
/// - cancelAuction()
/// - finalizeAuction()
/// - adminCancelListing()
/// - adminCancelAuction()
/// - getListing()
/// - getAuction()
interface IMarketplace1155 is IMarketplaceBase {
    /*//////////////////////////////////////////////////////////////
                            LISTINGS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new fixed-price ERC1155 listing.
    /// @param params Listing creation parameters.
    /// @return listingId Newly created listing identifier.
    function createListing(
        MarketplaceTypes.CreateListingParams calldata params
    ) external returns (uint256 listingId);

    /// @notice Updates an existing listing.
    /// @param params Listing update parameters.
    function updateListing(
        MarketplaceTypes.UpdateListingParams calldata params
    ) external;

    /// @notice Cancels an active listing.
    /// @param listingId Listing identifier.
    function cancelListing(
        uint256 listingId
    ) external;

    /// @notice Purchases ERC1155 tokens from a listing.
    /// @dev
    /// Supports partial purchases.
    ///
    /// @param listingId Listing identifier.
    /// @param quantity Quantity to purchase.
    /// @param expectedPrice Expected unit price used for front-running protection.
    function buy(
        uint256 listingId,
        uint256 quantity,
        uint256 expectedPrice
    ) external payable;

    /*//////////////////////////////////////////////////////////////
                            AUCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new ERC1155 auction.
    /// @param params Auction creation parameters.
    /// @return auctionId Newly created auction identifier.
    function createAuction(
        MarketplaceTypes.CreateAuctionParams calldata params
    ) external returns (uint256 auctionId);

    /// @notice Places a bid on an active auction.
    /// @dev
    /// Supports both ETH and ERC20 bidding.
    ///
    /// @param auctionId Auction identifier.
    /// @param expectedHighestBid Expected highest bid.
    /// @param amount Bid amount.
    function placeBid(
        uint256 auctionId,
        uint256 expectedHighestBid,
        uint256 amount
    ) external payable;
}