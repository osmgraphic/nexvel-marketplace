// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";

/// @title Marketplace1155Storage
/// @author Nexvel
/// @notice Storage layout for the ERC1155 marketplace.
/// @dev
/// Stores only ERC1155 marketplace state.
///
/// IMPORTANT:
/// Never reorder existing variables.
/// Always append new variables before the storage gap.
abstract contract Marketplace1155Storage {
    /*//////////////////////////////////////////////////////////////
                            COUNTERS
    //////////////////////////////////////////////////////////////*/

    uint256 internal _nextListingId;

    uint256 internal _nextAuctionId;

    /*//////////////////////////////////////////////////////////////
                            LISTINGS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => MarketplaceTypes.Listing) internal _listings;

    /*//////////////////////////////////////////////////////////////
                            AUCTIONS
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => MarketplaceTypes.Auction) internal _auctions;

    /*//////////////////////////////////////////////////////////////
                            LOOKUPS
    //////////////////////////////////////////////////////////////*/

    mapping(bytes32 => uint256) internal _listingIdByAsset;

    mapping(bytes32 => uint256) internal _auctionIdByAsset;

    /*//////////////////////////////////////////////////////////////
                        LAZY MINT
    //////////////////////////////////////////////////////////////*/

    /// @notice Prevents voucher replay attacks.
    mapping(bytes32 => bool) internal _usedVouchers;

    /*//////////////////////////////////////////////////////////////
                            STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    uint256[50] private _gap;
}
