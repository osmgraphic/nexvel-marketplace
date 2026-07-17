// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";

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

    event ListingCancelled(uint256 indexed listingId, address indexed nft, uint256 indexed tokenId, address seller);

    event ListingUpdated(uint256 indexed listingId, uint256 newPrice, uint256 newExpiry);

    event ModuleRemoved(MarketplaceTypes.MarketplaceModule indexed moduleType, address indexed moduleAddress);

    event GlobalPauseUpdated(bool isPaused);

    event TradeLimitUpdated(uint256 newTradeLimit);

    event CollectionConfigUpdated(address indexed collection, bool isTradingAllowed, uint96 royaltyBps);

    event PaymentTokenRegistered(address indexed token, MarketplaceTypes.PaymentTokenConfig config);

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

    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 bidAmount, uint256 endTime);

    event AuctionSettled(uint256 indexed auctionId, address indexed winner, uint256 winningBid);

    event AuctionCancelled(uint256 indexed auctionId, address seller);

    /*//////////////////////////////////////////////////////////////
                            PAYMENTS
    //////////////////////////////////////////////////////////////*/

    event SellerPaid(address indexed seller, uint256 amount);

    event RoyaltyPaid(address indexed receiver, uint256 amount);

    event MarketplaceFeePaid(address indexed treasury, uint256 amount);

    event RefundWithdrawn(address indexed bidder, uint256 amount);

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

    event CollectionUpdated(address indexed collection, bool allowed);

    event PaymentTokenUpdated(address indexed token, bool allowed);

    event MarketplaceFeeUpdated(uint96 previousFee, uint96 newFee);

    event TreasuryUpdated(address indexed previousTreasury, address indexed newTreasury);

    event RegistryUpdated(address indexed previousRegistry, address indexed newRegistry);

    event ModuleUpdated(
        MarketplaceTypes.MarketplaceModule indexed moduleType, address indexed previousModule, address indexed newModule
    );

    event ModuleRegistered(MarketplaceTypes.MarketplaceModule indexed moduleType, address indexed moduleAddress);

    event ListingSold(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        address nft,
        uint256 tokenId,
        address paymentToken,
        uint256 salePrice,
        uint256 marketplaceFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
}
