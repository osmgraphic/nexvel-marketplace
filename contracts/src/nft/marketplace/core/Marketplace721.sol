// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {MarketplaceConstants} from "../libraries/MarketplaceConstants.sol";
import {MarketplaceErrors} from "../errors/MarketplaceErrors.sol";
import {MarketplaceEvents} from "../events/MarketplaceEvents.sol";
import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";

import {Marketplace721Storage} from "../storage/Marketplace721Storage.sol";

import {IMarketplace721} from "../interfaces/IMarketplace721.sol";
import {IMarketplaceRegistry} from "../interfaces/IMarketplaceRegistry.sol";

import {ValidationLib} from "../libraries/ValidationLib.sol";
import {ListingValidationLib} from "../libraries/ListingValidationLib.sol";
import {AuctionValidationLib} from "../libraries/AuctionValidationLib.sol";
import {RoyaltyLib} from "../libraries/RoyaltyLib.sol";
import {PaymentLib} from "../libraries/PaymentLib.sol";

/*//////////////////////////////////////////////////////////////
                        CONTRACT
//////////////////////////////////////////////////////////////*/

contract Marketplace721 is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Marketplace721Storage,
    IMarketplace721,
    IERC721Receiver
{
    /*//////////////////////////////////////////////////////////////
                            ROLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*//////////////////////////////////////////////////////////////
                            STATE
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes Marketplace721.
    function initialize(address admin, address registryAddress) external initializer {
        if (admin == address(0)) {
            revert MarketplaceErrors.ZeroAddress();
        }

        if (registryAddress == address(0)) {
            revert MarketplaceErrors.InvalidRegistry();
        }

        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);

        _registry = IMarketplaceRegistry(registryAddress);
    }

    /*//////////////////////////////////////////////////////////////
                        UUPS
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function reg() internal view returns (IMarketplaceRegistry) {
        return _registry;
    }

    function _assetKey(address nft, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nft, tokenId));
    }

    function getAuction(uint256 auctionId) external view override returns (MarketplaceTypes.Auction memory) {
        return _auctions[auctionId];
    }

    function adminCancelListing(uint256 listingId) external override onlyRole(ADMIN_ROLE) nonReentrant {
        MarketplaceTypes.Listing storage listing = _listings[listingId];

        if (listing.seller == address(0)) {
            revert MarketplaceErrors.ListingNotFound(listingId);
        }

        if (listing.status != MarketplaceTypes.ListingStatus.ACTIVE) {
            revert MarketplaceErrors.ListingInactive();
        }

        listing.status = MarketplaceTypes.ListingStatus.CANCELLED;

        delete _listingIdByAsset[_assetKey(listing.nft, listing.tokenId)];

        IERC721(listing.nft).safeTransferFrom(address(this), listing.seller, listing.tokenId);

        emit MarketplaceEvents.ListingCancelled(listingId, listing.nft, listing.tokenId, listing.seller);
    }

    function adminCancelAuction(uint256 auctionId) external override onlyRole(ADMIN_ROLE) nonReentrant {
        MarketplaceTypes.Auction storage auction = _auctions[auctionId];

        if (auction.seller == address(0)) {
            revert MarketplaceErrors.AuctionNotFound(auctionId);
        }

        bytes32 assetKey = _assetKey(auction.nft, auction.tokenId);

        _closeAuction(auction, MarketplaceTypes.AuctionStatus.CANCELLED);

        delete _auctionIdByAsset[assetKey];

        IERC721(auction.nft).safeTransferFrom(address(this), auction.seller, auction.tokenId);

        emit MarketplaceEvents.AuctionCancelled(auctionId, auction.seller);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC721 RECEIVER
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /*//////////////////////////////////////////////////////////////
                        VIEWS
    //////////////////////////////////////////////////////////////*/

    function version() external pure returns (string memory) {
        return MarketplaceConstants.MARKETPLACE_VERSION;
    }

    /*//////////////////////////////////////////////////////////////
                        CREATE LISTING
    //////////////////////////////////////////////////////////////*/

    function createListing(MarketplaceTypes.CreateListingParams calldata params)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 listingId)
    {
        IMarketplaceRegistry registryInstance = _registry;

        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        ListingValidationLib.validateCreateListing(params);

        if (!registryInstance.isCollectionSupported(params.nft)) {
            revert MarketplaceErrors.CollectionNotAllowed();
        }

        if (!registryInstance.isPaymentTokenSupported(params.paymentToken)) {
            revert MarketplaceErrors.PaymentTokenNotAllowed();
        }

        bytes32 assetKey = _assetKey(params.nft, params.tokenId);

        if (_listingIdByAsset[assetKey] != 0) {
            revert MarketplaceErrors.ListingAlreadyExists(params.nft, params.tokenId);
        }

        IERC721(params.nft).safeTransferFrom(msg.sender, address(this), params.tokenId);

        unchecked {
            ++_nextListingId;
        }

        listingId = _nextListingId;

        MarketplaceTypes.Listing storage listing = _listings[listingId];

        listing.id = listingId;
        listing.tokenId = params.tokenId;
        listing.quantity = 1;
        listing.pricePerUnit = params.pricePerUnit;

        listing.seller = msg.sender;
        listing.nft = params.nft;
        listing.paymentToken = params.paymentToken;

        listing.createdAt = uint64(block.timestamp);
        listing.expiry = params.expiry;

        listing.assetType = MarketplaceTypes.AssetType.ERC721;
        listing.status = MarketplaceTypes.ListingStatus.ACTIVE;

        _listingIdByAsset[assetKey] = listingId;

        emit MarketplaceEvents.ListingCreated(
            listingId,
            listing.nft,
            listing.tokenId,
            listing.seller,
            listing.quantity,
            listing.pricePerUnit,
            listing.paymentToken,
            listing.expiry
        );

        return listingId;
    }

    /*//////////////////////////////////////////////////////////////
                            BUY LISTING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplace721
    function buy(uint256 listingId, uint256 expectedPrice) external payable nonReentrant whenNotPaused {
        IMarketplaceRegistry registryInstance = _registry;

        MarketplaceTypes.Listing storage listing = _listings[listingId];

        ListingValidationLib.validatePurchase(listing, 1, expectedPrice, msg.sender);

        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        MarketplaceTypes.RoyaltyInfo memory royalty;

        (royalty.receiver, royalty.amount) =
            RoyaltyLib.calculateRoyalty(listing.nft, listing.tokenId, listing.pricePerUnit);

        uint96 marketplaceFeeBps = registryInstance.marketplaceFeeBps();

        uint256 marketplaceFee = PaymentLib.calculateMarketplaceFee(listing.pricePerUnit, marketplaceFeeBps);

        MarketplaceTypes.FeeBreakdown memory breakdown =
            PaymentLib.buildFeeBreakdown(listing.pricePerUnit, marketplaceFee, royalty.receiver, royalty.amount);

        if (PaymentLib.isNativeToken(listing.paymentToken)) {
            PaymentLib.validateNativePayment(listing.pricePerUnit, msg.value);
        } else {
            PaymentLib.validateERC20Payment(msg.value);
        }

        PaymentLib.distributeSale(listing.paymentToken, msg.sender, _registry.treasury(), listing.seller, breakdown);

        IERC721(listing.nft).safeTransferFrom(address(this), msg.sender, listing.tokenId);

        listing.status = MarketplaceTypes.ListingStatus.SOLD;

        delete _listings[listingId];
        delete _listingIdByAsset[_assetKey(listing.nft, listing.tokenId)];

        emit MarketplaceEvents.ListingSold(
            listingId,
            msg.sender,
            listing.seller,
            listing.nft,
            listing.tokenId,
            listing.paymentToken,
            listing.pricePerUnit,
            marketplaceFee,
            royalty.receiver,
            royalty.amount
        );
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL LISTING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplace721
    function cancelListing(uint256 listingId) external nonReentrant whenNotPaused {
        MarketplaceTypes.Listing storage listing = _listings[listingId];

        ListingValidationLib.validateCancelListing(listing, msg.sender);

        if (listing.status != MarketplaceTypes.ListingStatus.ACTIVE) {
            revert MarketplaceErrors.ListingInactive();
        }

        listing.status = MarketplaceTypes.ListingStatus.CANCELLED;

        delete _listingIdByAsset[_assetKey(listing.nft, listing.tokenId)];

        listing.quantity = 0;

        IERC721(listing.nft).safeTransferFrom(address(this), listing.seller, listing.tokenId);

        emit MarketplaceEvents.ListingCancelled(listingId, listing.nft, listing.tokenId, listing.seller);
    }

    /*//////////////////////////////////////////////////////////////
                        GET LISTING
    //////////////////////////////////////////////////////////////*/

    function getListing(uint256 listingId) external view returns (MarketplaceTypes.Listing memory) {
        return _listings[listingId];
    }

    /*//////////////////////////////////////////////////////////////
                    LISTING EXISTS
    //////////////////////////////////////////////////////////////*/

    function listingExists(uint256 listingId) external view returns (bool) {
        return _listings[listingId].seller != address(0);
    }

    /*//////////////////////////////////////////////////////////////
                    TOTAL LISTINGS
    //////////////////////////////////////////////////////////////*/

    function totalListings() external view returns (uint256) {
        return _nextListingId;
    }

    function totalAuctions() external view returns (uint256) {
        return _nextAuctionId;
    }

    /*//////////////////////////////////////////////////////////////
                        UPDATE LISTING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplace721
    function updateListing(MarketplaceTypes.UpdateListingParams calldata params) external nonReentrant whenNotPaused {
        IMarketplaceRegistry registryInstance = _registry;

        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        MarketplaceTypes.Listing storage listing = _listings[params.listingId];

        if (listing.seller == address(0)) {
            revert MarketplaceErrors.ListingNotFound(params.listingId);
        }

        if (listing.seller != msg.sender) {
            revert MarketplaceErrors.NotListingOwner();
        }

        if (listing.status != MarketplaceTypes.ListingStatus.ACTIVE) {
            revert MarketplaceErrors.ListingInactive();
        }

        ValidationLib.validatePrice(params.newPrice);

        if (params.newExpiry != 0 && params.newExpiry <= block.timestamp) {
            revert MarketplaceErrors.InvalidExpiry();
        }

        listing.pricePerUnit = params.newPrice;
        listing.expiry = params.newExpiry;

        emit MarketplaceEvents.ListingUpdated(params.listingId, params.newPrice, params.newExpiry);
    }

    /*//////////////////////////////////////////////////////////////
                        CREATE AUCTION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplace721
    function createAuction(MarketplaceTypes.CreateAuctionParams calldata params)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 auctionId)
    {
        IMarketplaceRegistry registryInstance = _registry;

        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        AuctionValidationLib.validateCreateAuction(params);

        if (!registryInstance.isCollectionSupported(params.nft)) {
            revert MarketplaceErrors.CollectionNotAllowed();
        }

        if (!registryInstance.isPaymentTokenSupported(params.paymentToken)) {
            revert MarketplaceErrors.PaymentTokenNotAllowed();
        }

        bytes32 assetKey = keccak256(abi.encodePacked(params.nft, params.tokenId));

        if (_auctionIdByAsset[assetKey] != 0) {
            revert MarketplaceErrors.AuctionAlreadyExists(params.nft, params.tokenId);
        }

        IERC721(params.nft).safeTransferFrom(msg.sender, address(this), params.tokenId);

        unchecked {
            ++_nextAuctionId;
        }

        auctionId = _nextAuctionId;

        MarketplaceTypes.Auction storage auction = _auctions[auctionId];

        auction.id = auctionId;
        auction.seller = msg.sender;

        auction.nft = params.nft;
        auction.tokenId = params.tokenId;

        auction.quantity = 1;

        auction.paymentToken = params.paymentToken;

        auction.minimumPrice = params.minimumPrice;

        auction.highestBid = 0;
        auction.highestBidder = address(0);

        auction.startTime = uint64(block.timestamp);

        auction.endTime = uint64(block.timestamp + params.duration);

        auction.assetType = MarketplaceTypes.AssetType.ERC721;

        auction.status = MarketplaceTypes.AuctionStatus.ACTIVE;

        _auctionIdByAsset[assetKey] = auctionId;

        emit MarketplaceEvents.AuctionCreated(
            auctionId, params.nft, params.tokenId, msg.sender, 1, params.minimumPrice, auction.endTime
        );
    }

    function pendingRefund(address bidder, address paymentToken) external view returns (uint256) {
        return _pendingRefunds[bidder][paymentToken];
    }

    function withdrawRefund(address paymentToken) external nonReentrant {
        uint256 amount = _pendingRefunds[msg.sender][paymentToken];

        if (amount == 0) {
            revert MarketplaceErrors.NoRefundAvailable();
        }

        _pendingRefunds[msg.sender][paymentToken] = 0;

        PaymentLib.refundBid(paymentToken, msg.sender, amount);

        emit MarketplaceEvents.RefundWithdrawn(msg.sender, amount);
    }

    function _updateHighestBid(MarketplaceTypes.Auction storage auction, address bidder, uint256 amount) internal {
        auction.highestBid = amount;
        auction.highestBidder = bidder;
        auction.fundsEscrowed = true;

        unchecked {
            ++auction.bidCount;
        }
    }

    function _creditRefund(address bidder, address paymentToken, uint256 amount) internal {
        if (bidder == address(0) || amount == 0) {
            return;
        }

        _pendingRefunds[bidder][paymentToken] += amount;
    }

    /*//////////////////////////////////////////////////////////////
                            PLACE BID
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplace721
    function placeBid(uint256 auctionId, uint256 expectedHighestBid, uint256 amount)
        external
        payable
        override
        nonReentrant
        whenNotPaused
    {
        IMarketplaceRegistry registryInstance = _registry;

        // Global protocol pause
        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        MarketplaceTypes.Auction storage auction = _auctions[auctionId];

        MarketplaceTypes.BidParams memory params =
            MarketplaceTypes.BidParams({auctionId: auctionId, amount: amount, expectedHighestBid: expectedHighestBid});

        // Validate auction & bid
        AuctionValidationLib.validateBid(auction, params, msg.sender);

        // Escrow bidder funds
        PaymentLib.escrowBid(auction.paymentToken, msg.sender, amount, msg.value);

        // Credit refund to previous highest bidder
        _creditRefund(auction.highestBidder, auction.paymentToken, auction.highestBid);

        // Update highest bid
        _updateHighestBid(auction, msg.sender, amount);

        // Anti-sniping extension
        if (
            auction.endTime > block.timestamp
                && auction.endTime - block.timestamp <= MarketplaceConstants.AUCTION_EXTENSION_WINDOW
        ) {
            auction.endTime += uint64(MarketplaceConstants.AUCTION_EXTENSION_DURATION);
        }

        emit MarketplaceEvents.BidPlaced(auctionId, msg.sender, amount, auction.endTime);
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL AUCTION
    //////////////////////////////////////////////////////////////*/

    function _closeAuction(MarketplaceTypes.Auction storage auction, MarketplaceTypes.AuctionStatus status) internal {
        auction.status = status;
        auction.quantity = 0;
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL AUCTION
    //////////////////////////////////////////////////////////////*/

    function cancelAuction(uint256 auctionId) external override nonReentrant whenNotPaused {
        IMarketplaceRegistry registryInstance = _registry;

        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        MarketplaceTypes.Auction storage auction = _auctions[auctionId];

        AuctionValidationLib.validateCancelAuction(auction, msg.sender);

        bytes32 assetKey = _assetKey(auction.nft, auction.tokenId);

        // Effects
        _closeAuction(auction, MarketplaceTypes.AuctionStatus.CANCELLED);

        delete _auctionIdByAsset[assetKey];
        delete _auctions[auctionId];

        // Interaction
        IERC721(auction.nft).safeTransferFrom(address(this), auction.seller, auction.tokenId);

        emit MarketplaceEvents.AuctionCancelled(auctionId, auction.seller);
    }

    /*//////////////////////////////////////////////////////////////
                        FINALIZE AUCTION
    //////////////////////////////////////////////////////////////*/

    function finalizeAuction(uint256 auctionId) external override nonReentrant whenNotPaused {
        IMarketplaceRegistry registryInstance = _registry;
        uint96 marketplaceFeeBps = registryInstance.marketplaceFeeBps();

        address treasury = registryInstance.treasury();

        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        MarketplaceTypes.Auction storage auction = _auctions[auctionId];

        AuctionValidationLib.validateSettlement(auction);

        MarketplaceTypes.RoyaltyInfo memory royalty;

        (royalty.receiver, royalty.amount) =
            RoyaltyLib.calculateRoyalty(auction.nft, auction.tokenId, auction.highestBid);

        uint256 marketplaceFee = PaymentLib.calculateMarketplaceFee(auction.highestBid, marketplaceFeeBps);

        MarketplaceTypes.FeeBreakdown memory breakdown =
            PaymentLib.buildFeeBreakdown(auction.highestBid, marketplaceFee, royalty.receiver, royalty.amount);

        // Release escrowed funds
        PaymentLib.settleEscrowedAuction(auction.paymentToken, treasury, auction.seller, breakdown);

        // Transfer NFT to winner
        PaymentLib.releaseERC721(auction.nft, auction.highestBidder, auction.tokenId);

        // Close auction
        _closeAuction(auction, MarketplaceTypes.AuctionStatus.ENDED);

        // Remove active lookup
        delete _auctionIdByAsset[_assetKey(auction.nft, auction.tokenId)];

        emit MarketplaceEvents.AuctionSettled(auctionId, auction.highestBidder, auction.highestBid);
    }
}
