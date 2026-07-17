// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";

/// @title IMarketplaceBase
/// @author Nexvel
/// @notice Base marketplace interface shared by ERC721 and ERC1155 marketplace modules.
/// @dev
/// Contains only functionality common to all marketplace implementations.
/// Asset-specific operations such as creating listings or purchasing assets
/// are intentionally defined in their respective interfaces.
///
/// Implemented by:
/// - IMarketplace721
/// - IMarketplace1155
interface IMarketplaceBase {
    /*//////////////////////////////////////////////////////////////
                            AUCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Cancels an active auction.
    /// @dev Can only be called by the auction creator before a valid bid exists.
    /// @param auctionId Auction identifier.
    function cancelAuction(uint256 auctionId) external;

    /// @notice Finalizes a completed auction.
    /// @dev Transfers the NFT to the highest bidder and distributes payment.
    /// @param auctionId Auction identifier.
    function finalizeAuction(uint256 auctionId) external;

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    /// @notice Forcefully cancels a listing.
    /// @dev Intended for emergency actions or governance intervention.
    /// @param listingId Listing identifier.
    function adminCancelListing(uint256 listingId) external;

    /// @notice Forcefully cancels an auction.
    /// @dev Intended for emergency actions or governance intervention.
    /// @param auctionId Auction identifier.
    function adminCancelAuction(uint256 auctionId) external;

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns complete listing information.
    /// @dev Reverts if the listing does not exist.
    /// @param listingId Listing identifier.
    /// @return listing Listing information.
    function getListing(uint256 listingId) external view returns (MarketplaceTypes.Listing memory listing);

    /// @notice Returns complete auction information.
    /// @dev Reverts if the auction does not exist.
    /// @param auctionId Auction identifier.
    /// @return auction Auction information.
    function getAuction(uint256 auctionId) external view returns (MarketplaceTypes.Auction memory auction);
}
