// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MarketplaceErrors
/// @author Nexvel
/// @notice Centralized custom errors used across the Nexvel Marketplace.
/// @dev Using custom errors significantly reduces deployment size and gas costs.
library MarketplaceErrors {
    /*//////////////////////////////////////////////////////////////
                            COMMON
    //////////////////////////////////////////////////////////////*/

    error ZeroAddress();
    error ZeroAmount();
    error InvalidAmount();
    error InvalidPrice(uint256 provided);
    error InvalidQuantity();
    error InvalidTokenId();
    error InvalidDuration(uint256 provided, uint256 minimum, uint256 maximum);
    error InvalidExpiry();
    error InvalidSignature();
    error InvalidCaller();
    error InvalidRecipient();
    error InvalidPaymentToken();
    error InvalidCollection();
    error InvalidAddress(address account);
    error InvalidRoyalty();
    error ValidationFailed();
    error AuctionNotStarted();
    error InvalidTradeValue();
    error UnsupportedPaymentToken();
    error PaymentTokenDisabled();
    error UnsupportedCollection();
    error CollectionTradingDisabled();
    error PriceChanged();
    error BidStateChanged();
    error NotListingOwner();
    error CannotBuyOwnListing();
    error NotAuctionOwner();
    error AuctionAlreadyHasBid();
    error NoWinningBid();
    error InvalidWinner();
    error DeadlineExpired();
    error InvalidMarketplaceFee();
    error InvalidTreasury(address treasury);
    error ModuleNotRegistered();

    /*//////////////////////////////////////////////////////////////
                        ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error OnlyAdmin();
    error OnlyOperator();
    error OnlyCreator();
    error OnlySeller();
    error OnlyBuyer();

    /*//////////////////////////////////////////////////////////////
                        MARKETPLACE STATE
    //////////////////////////////////////////////////////////////*/

    error MarketplacePaused();
    error GlobalMarketplacePaused();

    /*//////////////////////////////////////////////////////////////
                            LISTINGS
    //////////////////////////////////////////////////////////////*/

    error ListingAlreadyExists(address nft, uint256 tokenId);

    error ListingNotFound(uint256 listingId);
    error ListingInactive();
    error ListingExpired();
    error ListingAlreadyCancelled();

    /*//////////////////////////////////////////////////////////////
                            AUCTIONS
    //////////////////////////////////////////////////////////////*/

    error AuctionAlreadyExists(address nft, uint256 tokenId);

    error AuctionNotFound(uint256 auctionId);
    error AuctionEnded();
    error AuctionNotEnded();
    error AuctionCancelled();

    error BidTooLow();
    error SellerCannotBid();
    error HighestBidderCannotWithdraw();

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    error NotOwner(address expected, address actual);
    error SelfPurchase();
    error MarketplaceNotApproved();
    error MarketplaceNotOwner();

    /*//////////////////////////////////////////////////////////////
                            PAYMENT
    //////////////////////////////////////////////////////////////*/

    error WrongPaymentAmount(uint256 expected, uint256 received);

    error ETHTransferFailed(address receiver, uint256 amount);

    error ERC20TransferFailed(address token, address receiver, uint256 amount);
    error PaymentFailed();
    error RefundFailed();
    error NoRefundAvailable();

    /*//////////////////////////////////////////////////////////////
                                FEES
    //////////////////////////////////////////////////////////////*/

    error MarketplaceFeeTooHigh(uint96 provided, uint96 maximum);
    error RoyaltyTooHigh(uint256 royalty, uint256 maximum);
    error RoyaltyExceedsSellerAmount();

    /*//////////////////////////////////////////////////////////////
                            LIMITS
    //////////////////////////////////////////////////////////////*/

    error TradeLimitExceeded(uint256 amount, uint256 maximum);
    error PriceExceedsLimit();

    /*//////////////////////////////////////////////////////////////
                        COLLECTIONS
    //////////////////////////////////////////////////////////////*/

    error CollectionNotAllowed();
    error CollectionAlreadyAllowed();
    error CollectionAlreadyBlocked();

    /*//////////////////////////////////////////////////////////////
                        PAYMENT TOKENS
    //////////////////////////////////////////////////////////////*/

    error PaymentTokenNotAllowed();
    error PaymentTokenAlreadyAllowed();
    error PaymentTokenAlreadyBlocked();

    /*//////////////////////////////////////////////////////////////
                            ERC721
    //////////////////////////////////////////////////////////////*/

    error NotERC721();
    error ERC721TransferFailed();

    /*//////////////////////////////////////////////////////////////
                            ERC1155
    //////////////////////////////////////////////////////////////*/

    error NotERC1155();
    error ERC1155TransferFailed();
    error InsufficientQuantity();

    /*//////////////////////////////////////////////////////////////
                            LAZY MINT
    //////////////////////////////////////////////////////////////*/

    error VoucherAlreadyUsed();
    error VoucherExpired();
    error InvalidVoucher();
    error InvalidCreator();

    /*//////////////////////////////////////////////////////////////
                            REGISTRY
    //////////////////////////////////////////////////////////////*/

    error InvalidRegistry();
    error RegistryNotConfigured();
    error RegistryAlreadyInitialized();

    /*//////////////////////////////////////////////////////////////
                            UPGRADES
    //////////////////////////////////////////////////////////////*/

    error UpgradeNotAuthorized();
    error InvalidImplementation();
}
