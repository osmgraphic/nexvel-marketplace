// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceConfigStorage} from "./";
import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";

/// @title Marketplace721Storage
/// @author Nexvel
/// @notice Storage layout for the ERC721 marketplace.
/// @dev
/// This contract stores only ERC721 marketplace state.
/// It MUST NOT contain business logic.
///
/// Storage Responsibilities:
/// - ERC721 Listings
/// - ERC721 Auctions
/// - Counters
/// - Asset Lookup
///
/// IMPORTANT:
/// Never reorder existing variables.
/// Always append new variables before the storage gap.
abstract contract Marketplace721Storage is MarketplaceConfigStorage {

    /*//////////////////////////////////////////////////////////////
                            COUNTERS
    //////////////////////////////////////////////////////////////*/

    uint256 internal _nextListingId;

    uint256 internal _nextAuctionId;

    /*//////////////////////////////////////////////////////////////
                            LISTINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => MarketplaceTypes.Listing)
        internal _listings;

    /*//////////////////////////////////////////////////////////////
                            AUCTIONS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => MarketplaceTypes.Auction)
        internal _auctions;

    /*//////////////////////////////////////////////////////////////
                            LOOKUPS
    //////////////////////////////////////////////////////////////*/

    mapping(bytes32 => uint256)
        internal _listingIdByAsset;

    mapping(bytes32 => uint256)
        internal _auctionIdByAsset;

    /*//////////////////////////////////////////////////////////////
                            STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    uint256[50] private __gap;
}