// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MarketplaceEvents
/// @notice Shared marketplace events.
abstract contract MarketplaceEvents {

    /*//////////////////////////////////////////////////////////////
                            LISTINGS
    //////////////////////////////////////////////////////////////*/

    event ListingCreated(
        uint256 indexed listingId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 quantity,
        uint256 pricePerUnit,
        address paymentToken,
        uint256 expiry
    );

    event ListingPurchased(
        uint256 indexed listingId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 quantity,
        uint256 pricePerUnit,
        uint256 totalPrice,
        address paymentToken
    );

    event ListingCancelled(
        uint256 indexed listingId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller
    );

    /*//////////////////////////////////////////////////////////////
                            AUCTIONS
    //////////////////////////////////////////////////////////////*/

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 quantity,
        uint256 minimumPrice,
        uint256 endTime
    );

    event BidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount,
        uint256 endTime
    );

    event AuctionSettled(
        uint256 indexed auctionId,
        address indexed winner,
        uint256 winningBid
    );

    event AuctionCancelled(
        uint256 indexed auctionId,
        address seller
    );

    /*//////////////////////////////////////////////////////////////
                            PAYMENTS
    //////////////////////////////////////////////////////////////*/

    event SellerPaid(
        address indexed seller,
        uint256 amount
    );

    event RoyaltyPaid(
        address indexed receiver,
        uint256 amount
    );

    event MarketplaceFeePaid(
        address indexed treasury,
        uint256 amount
    );

    event RefundWithdrawn(
        address indexed bidder,
        uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                            LAZY MINT
    //////////////////////////////////////////////////////////////*/

    event LazyMintPurchased(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed creator,
        address buyer,
        uint256 quantity,
        uint256 totalPrice
    );

    /*//////////////////////////////////////////////////////////////
                            ADMIN
    //////////////////////////////////////////////////////////////*/

    event CollectionUpdated(
        address indexed collection,
        bool allowed
    );

    event PaymentTokenUpdated(
        address indexed token,
        bool allowed
    );

    event MarketplaceFeeUpdated(
        uint96 previousFee,
        uint96 newFee
    );

    event TreasuryUpdated(
        address indexed previousTreasury,
        address indexed newTreasury
    );

    event RegistryUpdated(
        address indexed previousRegistry,
        address indexed newRegistry
    );


    event ModuleUpdated(
        MarketplaceTypes.MarketplaceModule indexed moduleType,
        address indexed previousModule,
        address indexed newModule
    );
}