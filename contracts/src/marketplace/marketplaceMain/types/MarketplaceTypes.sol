// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MarketplaceTypes
/// @author Nexvel
/// @notice Shared enums and structs used across the Nexvel Marketplace Protocol.
/// @dev
/// This library contains only shared data types.
/// No business logic should ever be added here.
///
/// IMPORTANT:
/// - Never reorder enum values.
/// - Never reorder struct fields.
/// - Only append new values or fields in future upgrades.
library MarketplaceTypes {

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    enum AssetType {
        ERC721,
        ERC1155
    }

    enum MarketplaceModule {
        NFT721,
        NFT1155,
        PAYMENT,
        OFFER,
        BUNDLE,
        RENTAL,
        LAUNCHPAD,
        ESCROW,
        ORACLE
    }

    /*//////////////////////////////////////////////////////////////
                        PROTOCOL CONFIG
    //////////////////////////////////////////////////////////////*/

    struct MarketplaceConfig {
        address treasury;
        uint96 marketplaceFeeBps;
        bool globalPaused;
        uint256 maxTradeValue;
    }

    struct ModuleInfo {
        address implementation;
        bool active;
        uint64 registeredAt;
    }

    struct CollectionConfig {
        bool supported;
        bool tradingEnabled;
        bool lazyMintEnabled;
        AssetType assetType;
    }

    struct PaymentTokenConfig {
        bool supported;
        bool enabled;
        uint8 decimals;
    }

    /*//////////////////////////////////////////////////////////////
                            MARKETPLACE
    //////////////////////////////////////////////////////////////*/

    struct Listing {
        uint256 id;
        uint256 tokenId;
        uint256 quantity;
        uint256 pricePerUnit;

        address seller;
        address nft;
        address paymentToken;

        uint64 createdAt;
        uint64 expiry;

        AssetType assetType;
    }

    struct AuctionStatus {
        bool active;
        bool ended;
        bool cancelled;
    }

struct Auction {
    uint256 id;

    address seller;
    address nft;
    uint256 tokenId;

    uint256 quantity;

    address paymentToken;

    uint256 minimumPrice;
    uint256 highestBid;

    address highestBidder;

    uint64 startTime;
    uint64 endTime;

    AssetType assetType;

    AuctionStatus status;
}

    struct BidParams {
    uint256 auctionId;
    uint256 amount;
    uint256 expectedHighestBid;
}

    /*//////////////////////////////////////////////////////////////
                            PAYMENT
    //////////////////////////////////////////////////////////////*/

    struct FeeBreakdown {
        uint256 totalPrice;
        uint256 royaltyAmount;
        uint256 marketplaceFee;
        uint256 sellerAmount;
    }

    struct PaymentRequest {
        address payer;
        address buyer;
        address seller;
        address paymentToken;
        uint256 amount;
    }

    struct RoyaltyInfo {
        address receiver;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                    INPUT PARAMETERS
//////////////////////////////////////////////////////////////*/

/// @notice Parameters required to create a fixed-price ERC721 listing.
struct CreateListingParams {
    address nft;
    uint256 tokenId;
    uint256 quantity;
    address paymentToken;
    uint256 pricePerUnit;
    uint64 expiry;
}

/// @notice Parameters required to update a listing.
struct UpdateListingParams {
    uint256 listingId;
    uint256 newPrice;
    uint64 newExpiry;
}

/// @notice Parameters required to create an ERC721 auction.
struct CreateAuctionParams {
    address nft;
    uint256 tokenId;
    uint256 quantity;  
    address paymentToken;
    uint256 minimumPrice;
    uint64 duration;
}
}