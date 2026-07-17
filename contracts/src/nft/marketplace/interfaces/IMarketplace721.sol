// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";
import {IMarketplaceBase} from "./IMarketplaceBase.sol";

/// @title IMarketplace721
/// @author Nexvel
/// @notice Interface for the Nexvel ERC721 Marketplace module.
/// @dev
/// Defines ERC721-specific marketplace operations.
/// Common marketplace functionality is inherited from IMarketplaceBase.
///
/// Inherited:
/// - cancelAuction()
/// - finalizeAuction()
/// - adminCancelListing()
/// - adminCancelAuction()
/// - getListing()
/// - getAuction()
interface IMarketplace721 is IMarketplaceBase {
    /*//////////////////////////////////////////////////////////////
                            LISTINGS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new fixed-price ERC721 listing.
    /// @param params Listing creation parameters.
    /// @return listingId Newly created listing identifier.
    function createListing(MarketplaceTypes.CreateListingParams calldata params) external returns (uint256 listingId);

    /// @notice Updates an existing listing.
    /// @param params Listing update parameters.
    function updateListing(MarketplaceTypes.UpdateListingParams calldata params) external;

    /// @notice Cancels an active listing.
    /// @param listingId Listing identifier.
    function cancelListing(uint256 listingId) external;

    /// @notice Purchases a listed ERC721 NFT.
    /// @dev
    /// `expectedPrice` protects against front-running by ensuring the buyer
    /// executes the transaction only if the on-chain listing price matches
    /// the expected value.
    ///
    /// The function supports both ETH and ERC20 payments.
    ///
    /// @param listingId Listing identifier.
    /// @param expectedPrice Expected listing price.
    function buy(uint256 listingId, uint256 expectedPrice) external payable;

    /*//////////////////////////////////////////////////////////////
                            AUCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new ERC721 auction.
    /// @param params Auction creation parameters.
    /// @return auctionId Newly created auction identifier.
    function createAuction(MarketplaceTypes.CreateAuctionParams calldata params) external returns (uint256 auctionId);

    /// @notice Places a bid on an active auction.
    /// @dev
    /// `expectedHighestBid` protects against race conditions and
    /// front-running by verifying the current highest bid before execution.
    ///
    /// Supports both ETH and ERC20 bidding.
    ///
    /// @param auctionId Auction identifier.
    /// @param expectedHighestBid Expected current highest bid.
    /// @param amount Bid amount.
    function placeBid(uint256 auctionId, uint256 expectedHighestBid, uint256 amount) external payable;
}
