// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

import {MarketplaceConstants} from "../libraries/MarketplaceConstants.sol";
import {MarketplaceErrors} from "../errors/MarketplaceErrors.sol";
import {MarketplaceEvents} from "../events/MarketplaceEvents.sol";
import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";

import {Marketplace1155Storage} from "../storage/Marketplace1155Storage.sol";

import {IMarketplace1155} from "../interfaces/IMarketplace1155.sol";
import {IMarketplaceRegistry} from "../interfaces/IMarketplaceRegistry.sol";

import {ValidationLib} from "../libraries/ValidationLib.sol";
import {ListingValidationLib} from "../libraries/ListingValidationLib.sol";
import {AuctionValidationLib} from "../libraries/AuctionValidationLib.sol";
import {RoyaltyLib} from "../libraries/RoyaltyLib.sol";
import {PaymentLib} from "../libraries/PaymentLib.sol";

/*//////////////////////////////////////////////////////////////
                        CONTRACT
//////////////////////////////////////////////////////////////*/

contract Marketplace1155 is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard,
    ERC165,
    IERC1155Receiver,
    Marketplace1155Storage,
    IMarketplace1155
{
    /*//////////////////////////////////////////////////////////////
                            ROLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /*//////////////////////////////////////////////////////////////
                            STATE
    //////////////////////////////////////////////////////////////*/

    IMarketplaceRegistry internal _registry;

    mapping(address => mapping(address => uint256)) internal _pendingRefunds;

    /*//////////////////////////////////////////////////////////////
                        INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(address admin, address registryAddress) external initializer {
        if (admin == address(0)) {
            revert MarketplaceErrors.ZeroAddress();
        }

        if (registryAddress == address(0)) {
            revert MarketplaceErrors.InvalidRegistry();
        }

        __AccessControl_init();
        __Pausable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);

        _registry = IMarketplaceRegistry(registryAddress);
    }

    /*//////////////////////////////////////////////////////////////
                        UUPS
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function reg() internal view returns (IMarketplaceRegistry) {
        return _registry;
    }

    function _assetKey(address nft, uint256 tokenId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(nft, tokenId));
    }

    /*//////////////////////////////////////////////////////////////
                    ERC1155 RECEIVER
    //////////////////////////////////////////////////////////////*/

    function onERC1155Received(address, address, uint256, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEWS
    //////////////////////////////////////////////////////////////*/

    function version() external pure returns (string memory) {
        return MarketplaceConstants.MARKETPLACE_VERSION;
    }

    function getListing(uint256 listingId) external view override returns (MarketplaceTypes.Listing memory) {
        return _listings[listingId];
    }

    function getAuction(uint256 auctionId) external view override returns (MarketplaceTypes.Auction memory) {
        return _auctions[auctionId];
    }

    function listingExists(uint256 listingId) external view returns (bool) {
        return _listings[listingId].seller != address(0);
    }

    function totalListings() external view returns (uint256) {
        return _nextListingId;
    }

    function totalAuctions() external view returns (uint256) {
        return _nextAuctionId;
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

        if (params.quantity == 0) {
            revert MarketplaceErrors.InvalidQuantity();
        }

        bytes32 assetKey = _assetKey(params.nft, params.tokenId);

        if (_listingIdByAsset[assetKey] != 0) {
            revert MarketplaceErrors.ListingAlreadyExists(params.nft, params.tokenId);
        }

        IERC1155(params.nft).safeTransferFrom(msg.sender, address(this), params.tokenId, params.quantity, "");

        unchecked {
            ++_nextListingId;
        }

        listingId = _nextListingId;

        MarketplaceTypes.Listing storage listing = _listings[listingId];

        listing.id = listingId;
        listing.tokenId = params.tokenId;
        listing.quantity = params.quantity;
        listing.pricePerUnit = params.pricePerUnit;

        listing.seller = msg.sender;
        listing.nft = params.nft;
        listing.paymentToken = params.paymentToken;

        listing.createdAt = uint64(block.timestamp);
        listing.expiry = params.expiry;

        listing.assetType = MarketplaceTypes.AssetType.ERC1155;
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
        PART-2 STARTS FROM updateListing()
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        UPDATE LISTING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplace1155
    function updateListing(MarketplaceTypes.UpdateListingParams calldata params)
        external
        override
        nonReentrant
        whenNotPaused
    {
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
                            BUY
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplace1155
    function buy(uint256 listingId, uint256 quantity, uint256 expectedPrice)
        external
        payable
        override
        nonReentrant
        whenNotPaused
    {
        IMarketplaceRegistry registryInstance = _registry;
        address treasury = registryInstance.treasury();

        MarketplaceTypes.Listing storage listing = _listings[listingId];

        bytes32 assetKey = _assetKey(listing.nft, listing.tokenId);

        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        ListingValidationLib.validatePurchase(listing, quantity, expectedPrice, msg.sender);

        if (quantity > listing.quantity) {
            revert MarketplaceErrors.InvalidQuantity();
        }

        uint256 totalPrice = listing.pricePerUnit * quantity;

        MarketplaceTypes.RoyaltyInfo memory royalty;

        (royalty.receiver, royalty.amount) = RoyaltyLib.calculateRoyalty(listing.nft, listing.tokenId, totalPrice);

        uint96 marketplaceFeeBps = registryInstance.marketplaceFeeBps();

        uint256 marketplaceFee = PaymentLib.calculateMarketplaceFee(totalPrice, marketplaceFeeBps);

        MarketplaceTypes.FeeBreakdown memory breakdown =
            PaymentLib.buildFeeBreakdown(totalPrice, marketplaceFee, royalty.receiver, royalty.amount);

        if (PaymentLib.isNativeToken(listing.paymentToken)) {
            PaymentLib.validateNativePayment(totalPrice, msg.value);
        } else {
            PaymentLib.validateERC20Payment(msg.value);
        }

        PaymentLib.distributeSale(listing.paymentToken, msg.sender, treasury, listing.seller, breakdown);

        IERC1155(listing.nft).safeTransferFrom(address(this), msg.sender, listing.tokenId, quantity, "");

        unchecked {
            listing.quantity -= quantity;
        }

        if (listing.quantity == 0) {
            listing.status = MarketplaceTypes.ListingStatus.SOLD;

            delete _listingIdByAsset[assetKey];

            // Keep the listing for historical records
            listing.quantity = 0;
        }

        emit MarketplaceEvents.ListingSold(
            listingId,
            msg.sender,
            listing.seller,
            listing.nft,
            listing.tokenId,
            listing.paymentToken,
            totalPrice,
            marketplaceFee,
            royalty.receiver,
            royalty.amount
        );
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL LISTING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplace1155
    function cancelListing(uint256 listingId) external override nonReentrant whenNotPaused {
        MarketplaceTypes.Listing storage listing = _listings[listingId];

        ListingValidationLib.validateCancelListing(listing, msg.sender);

        if (listing.status != MarketplaceTypes.ListingStatus.ACTIVE) {
            revert MarketplaceErrors.ListingInactive();
        }

        listing.status = MarketplaceTypes.ListingStatus.CANCELLED;

        delete _listingIdByAsset[_assetKey(listing.nft, listing.tokenId)];

        uint256 remainingQuantity = listing.quantity;

        listing.quantity = 0;

        IERC1155(listing.nft).safeTransferFrom(address(this), listing.seller, listing.tokenId, remainingQuantity, "");

        emit MarketplaceEvents.ListingCancelled(listingId, listing.nft, listing.tokenId, listing.seller);
    }

    /*//////////////////////////////////////////////////////////////
                        CREATE AUCTION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IMarketplace1155
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

        if (params.quantity == 0) {
            revert MarketplaceErrors.InvalidQuantity();
        }

        bytes32 assetKey = _assetKey(params.nft, params.tokenId);

        if (_auctionIdByAsset[assetKey] != 0) {
            revert MarketplaceErrors.AuctionAlreadyExists(params.nft, params.tokenId);
        }

        IERC1155(params.nft).safeTransferFrom(msg.sender, address(this), params.tokenId, params.quantity, "");

        unchecked {
            ++_nextAuctionId;
        }

        auctionId = _nextAuctionId;

        MarketplaceTypes.Auction storage auction = _auctions[auctionId];

        auction.id = auctionId;

        auction.seller = msg.sender;

        auction.nft = params.nft;
        auction.tokenId = params.tokenId;

        auction.quantity = params.quantity;

        auction.paymentToken = params.paymentToken;

        auction.minimumPrice = params.minimumPrice;

        auction.highestBid = 0;
        auction.highestBidder = address(0);

        auction.startTime = uint64(block.timestamp);

        auction.endTime = uint64(block.timestamp + params.duration);

        auction.assetType = MarketplaceTypes.AssetType.ERC1155;

        auction.status = MarketplaceTypes.AuctionStatus.ACTIVE;

        _auctionIdByAsset[assetKey] = auctionId;

        emit MarketplaceEvents.AuctionCreated(
            auctionId, params.nft, params.tokenId, msg.sender, params.quantity, params.minimumPrice, auction.endTime
        );
    }

    /*//////////////////////////////////////////////////////////////
                        REFUND HELPERS
    //////////////////////////////////////////////////////////////*/

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

    function _creditRefund(address bidder, address paymentToken, uint256 amount) internal {
        if (bidder == address(0) || amount == 0) {
            return;
        }

        _pendingRefunds[bidder][paymentToken] += amount;
    }

    function _updateHighestBid(MarketplaceTypes.Auction storage auction, address bidder, uint256 amount) internal {
        auction.highestBid = amount;
        auction.highestBidder = bidder;
        auction.fundsEscrowed = true;

        unchecked {
            ++auction.bidCount;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            PLACE BID
    //////////////////////////////////////////////////////////////*/

    function placeBid(uint256 auctionId, uint256 expectedHighestBid, uint256 amount)
        external
        payable
        override
        nonReentrant
        whenNotPaused
    {
        IMarketplaceRegistry registryInstance = _registry;

        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        MarketplaceTypes.Auction storage auction = _auctions[auctionId];

        MarketplaceTypes.BidParams memory params =
            MarketplaceTypes.BidParams({auctionId: auctionId, amount: amount, expectedHighestBid: expectedHighestBid});

        AuctionValidationLib.validateBid(auction, params, msg.sender);

        PaymentLib.escrowBid(auction.paymentToken, msg.sender, amount, msg.value);

        _creditRefund(auction.highestBidder, auction.paymentToken, auction.highestBid);

        _updateHighestBid(auction, msg.sender, amount);

        if (
            auction.endTime > block.timestamp
                && auction.endTime - block.timestamp <= MarketplaceConstants.AUCTION_EXTENSION_WINDOW
        ) {
            auction.endTime += uint64(MarketplaceConstants.AUCTION_EXTENSION_DURATION);
        }

        emit MarketplaceEvents.BidPlaced(auctionId, msg.sender, amount, auction.endTime);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
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

        uint256 quantity = auction.quantity;

        _closeAuction(auction, MarketplaceTypes.AuctionStatus.CANCELLED);

        delete _auctionIdByAsset[assetKey];

        IERC1155(auction.nft).safeTransferFrom(address(this), auction.seller, auction.tokenId, quantity, "");

        emit MarketplaceEvents.AuctionCancelled(auctionId, auction.seller);
    }

    /*//////////////////////////////////////////////////////////////
                        FINALIZE AUCTION
    //////////////////////////////////////////////////////////////*/

    function finalizeAuction(uint256 auctionId) external override nonReentrant whenNotPaused {
        IMarketplaceRegistry registryInstance = _registry;

        if (registryInstance.globalPaused()) {
            revert MarketplaceErrors.GlobalMarketplacePaused();
        }

        MarketplaceTypes.Auction storage auction = _auctions[auctionId];

        AuctionValidationLib.validateSettlement(auction);

        address treasury = registryInstance.treasury();

        uint96 marketplaceFeeBps = registryInstance.marketplaceFeeBps();

        MarketplaceTypes.RoyaltyInfo memory royalty;

        (royalty.receiver, royalty.amount) =
            RoyaltyLib.calculateRoyalty(auction.nft, auction.tokenId, auction.highestBid);

        uint256 marketplaceFee = PaymentLib.calculateMarketplaceFee(auction.highestBid, marketplaceFeeBps);

        MarketplaceTypes.FeeBreakdown memory breakdown =
            PaymentLib.buildFeeBreakdown(auction.highestBid, marketplaceFee, royalty.receiver, royalty.amount);

        uint256 quantity = auction.quantity;

        PaymentLib.settleEscrowedAuction(auction.paymentToken, treasury, auction.seller, breakdown);

        IERC1155(auction.nft).safeTransferFrom(address(this), auction.highestBidder, auction.tokenId, quantity, "");

        _closeAuction(auction, MarketplaceTypes.AuctionStatus.ENDED);

        delete _auctionIdByAsset[_assetKey(auction.nft, auction.tokenId)];

        emit MarketplaceEvents.AuctionSettled(auctionId, auction.highestBidder, auction.highestBid);
    }

    /*//////////////////////////////////////////////////////////////
                    ADMIN CANCEL LISTING
    //////////////////////////////////////////////////////////////*/

    function adminCancelListing(uint256 listingId) external override onlyRole(ADMIN_ROLE) nonReentrant {
        MarketplaceTypes.Listing storage listing = _listings[listingId];

        if (listing.seller == address(0)) {
            revert MarketplaceErrors.ListingNotFound(listingId);
        }

        if (listing.status != MarketplaceTypes.ListingStatus.ACTIVE) {
            revert MarketplaceErrors.ListingInactive();
        }

        uint256 quantity = listing.quantity;

        listing.status = MarketplaceTypes.ListingStatus.CANCELLED;

        listing.quantity = 0;

        delete _listingIdByAsset[_assetKey(listing.nft, listing.tokenId)];

        IERC1155(listing.nft).safeTransferFrom(address(this), listing.seller, listing.tokenId, quantity, "");

        emit MarketplaceEvents.ListingCancelled(listingId, listing.nft, listing.tokenId, listing.seller);
    }

    /*//////////////////////////////////////////////////////////////
                    ADMIN CANCEL AUCTION
    //////////////////////////////////////////////////////////////*/

    function adminCancelAuction(uint256 auctionId) external override onlyRole(ADMIN_ROLE) nonReentrant {
        MarketplaceTypes.Auction storage auction = _auctions[auctionId];

        if (auction.seller == address(0)) {
            revert MarketplaceErrors.AuctionNotFound(auctionId);
        }

        uint256 quantity = auction.quantity;

        bytes32 assetKey = _assetKey(auction.nft, auction.tokenId);

        _closeAuction(auction, MarketplaceTypes.AuctionStatus.CANCELLED);

        delete _auctionIdByAsset[assetKey];

        IERC1155(auction.nft).safeTransferFrom(address(this), auction.seller, auction.tokenId, quantity, "");

        emit MarketplaceEvents.AuctionCancelled(auctionId, auction.seller);
    }
}
