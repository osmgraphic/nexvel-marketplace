// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                NEXVEL MARKETPLACE V3 (HARDENED)
        ERC1155 Listings + Lazy Mint + Auctions
//////////////////////////////////////////////////////////////*/

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {NexvelERC1155Upgradeable} from "./NexvelERC1155Upgradeable.sol";
import {NexvelMarketplaceV2} from "./NexvelMarketplaceV2.sol";

/// @custom:oz-upgrades-from NexvelMarketplaceV2
contract NexvelMarketplaceV3 is NexvelMarketplaceV2, IERC1155Receiver {
    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                            ERC1155 LISTINGS
    //////////////////////////////////////////////////////////////*/

    struct Listing1155 {
        address seller;
        address nft;
        uint256 tokenId;
        uint256 pricePerUnit;
        uint256 quantity;
        address paymentToken;
    }

    uint256 public nextListing1155Id;
    mapping(uint256 => Listing1155) public listings1155;

    /*//////////////////////////////////////////////////////////////
                            ERC1155 AUCTIONS
    //////////////////////////////////////////////////////////////*/

    struct Auction1155 {
        address seller;
        address nft;
        uint256 tokenId;
        uint256 amount;
        uint256 minPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
    }

    mapping(uint256 => Auction1155) public auctions1155;
    uint256 public nextAuction1155Id;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Listed1155(
        uint256 indexed listingId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 quantity,
        uint256 pricePerUnit,
        address paymentToken
    );

    event Purchased1155(
        uint256 indexed listingId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 quantity,
        uint256 totalPrice,
        address paymentToken
    );

    event AuctionCreated1155(
        uint256 indexed auctionId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 amount,
        uint256 minPrice,
        uint256 endTime
    );

    event BidPlaced1155(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 newEndTime);

    event AuctionSettled1155(uint256 indexed auctionId, address winner, uint256 amount);

    event AuctionCancelled1155(uint256 indexed auctionId);

    event LazyMintPurchased(
        address indexed nft, uint256 indexed tokenId, address buyer, address creator, uint256 amount
    );

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initializeV3() external reinitializer(3) {}

    /*//////////////////////////////////////////////////////////////
                        ERC1155 FIXED LISTING
    //////////////////////////////////////////////////////////////*/

    function list1155(address nft, uint256 tokenId, uint256 quantity, uint256 pricePerUnit, address paymentToken)
        external
        nonReentrant
        whenNotPaused
        whenGlobalNotPaused
    {
        require(allowedCollections[nft], "Collection not allowed");
        _requireERC1155(nft);
        require(quantity > 0, "Invalid quantity");
        require(pricePerUnit > 0, "Invalid price");
        require(pricePerUnit <= maxTradeValue, "Price too high");

        IERC1155(nft).safeTransferFrom(msg.sender, address(this), tokenId, quantity, "");

        uint256 listingId = nextListing1155Id++;

        listings1155[listingId] = Listing1155({
            seller: msg.sender,
            nft: nft,
            tokenId: tokenId,
            pricePerUnit: pricePerUnit,
            quantity: quantity,
            paymentToken: paymentToken
        });

        emit Listed1155(listingId, nft, tokenId, msg.sender, quantity, pricePerUnit, paymentToken);
    }

    function buy1155(uint256 listingId, uint256 qty) external payable nonReentrant whenNotPaused whenGlobalNotPaused {
        Listing1155 storage listing = listings1155[listingId];

        require(listing.seller != address(0), "Listing missing");
        require(msg.sender != listing.seller, "Self purchase");
        require(qty > 0 && qty <= listing.quantity, "Invalid qty");

        uint256 totalPrice = listing.pricePerUnit * qty;
        require(totalPrice <= maxTradeValue, "Trade limit exceeded");
        require(msg.value == totalPrice, "Wrong price");

        _handlePayment(listing.nft, listing.tokenId, listing.seller, msg.sender, totalPrice);

        IERC1155(listing.nft).safeTransferFrom(address(this), msg.sender, listing.tokenId, qty, "");

        emit Purchased1155(
            listingId, listing.nft, listing.tokenId, listing.seller, msg.sender, qty, totalPrice, listing.paymentToken
        );

        listing.quantity -= qty;
        if (listing.quantity == 0) {
            delete listings1155[listingId];
        }
    }

    /*//////////////////////////////////////////////////////////////
                        ERC1155 LAZY MINT
    //////////////////////////////////////////////////////////////*/

    function buyLazyMint1155(
        address nft,
        NexvelERC1155Upgradeable.LazyMintVoucher calldata voucher,
        bytes calldata signature,
        uint256 amount
    ) external payable nonReentrant whenNotPaused whenGlobalNotPaused {
        require(allowedCollections[nft], "Collection not allowed");
        _requireERC1155(nft);
        require(amount > 0, "Invalid amount");
        require(msg.sender != voucher.creator, "Self purchase");
        require(voucher.creator != address(0), "Invalid creator");
        require(voucher.tokenId != 0, "Invalid token");

        uint256 totalPrice = voucher.price * amount;
        require(totalPrice <= maxTradeValue, "Trade limit exceeded");
        require(msg.value == totalPrice, "Wrong value");

        NexvelERC1155Upgradeable nft1155 = NexvelERC1155Upgradeable(nft);

        // Mint to marketplace first (custodial flow)
        nft1155.lazyMint(voucher, signature, amount, address(this));

        // Use new hardened buyer-tracking payment
        _handlePayment(
            nft,
            voucher.tokenId,
            voucher.creator,
            msg.sender, // ✅ Correct buyer tracking
            totalPrice
        );

        // Transfer to buyer
        IERC1155(nft).safeTransferFrom(address(this), msg.sender, voucher.tokenId, amount, "");
    }

    /*//////////////////////////////////////////////////////////////
                        ERC1155 AUCTIONS
    //////////////////////////////////////////////////////////////*/

    function createAuction1155(address nft, uint256 tokenId, uint256 amount, uint256 minPrice, uint256 duration)
        external
        nonReentrant
        whenNotPaused
        whenGlobalNotPaused
    {
        require(allowedCollections[nft], "Collection not allowed");
        _requireERC1155(nft);
        require(amount > 0, "Invalid amount");
        require(minPrice > 0, "Invalid min price");
        require(minPrice <= maxTradeValue, "Price too high");
        require(duration >= 10 minutes, "Duration too short");
        require(duration <= MAX_AUCTION_DURATION, "Duration too long");

        IERC1155(nft).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        uint256 auctionId = ++nextAuction1155Id;

        auctions1155[auctionId] = Auction1155({
            seller: msg.sender,
            nft: nft,
            tokenId: tokenId,
            amount: amount,
            minPrice: minPrice,
            highestBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + duration
        });

        emit AuctionCreated1155(auctionId, nft, tokenId, msg.sender, amount, minPrice, block.timestamp + duration);
    }

    function bid1155(uint256 auctionId) external payable nonReentrant whenNotPaused whenGlobalNotPaused {
        Auction1155 storage a = auctions1155[auctionId];

        require(a.endTime != 0, "Auction missing");
        require(block.timestamp < a.endTime, "Auction ended");
        require(msg.sender != a.seller, "Seller cannot bid");
        require(msg.value <= maxTradeValue, "Trade limit exceeded");

        uint256 minBid = a.highestBid == 0 ? a.minPrice : (a.highestBid * (10_000 + MIN_BID_INCREMENT_BPS)) / 10_000;

        require(msg.value >= minBid, "Bid too low");

        if (a.highestBidder != address(0)) {
            pendingRefunds[a.highestBidder] += a.highestBid;
        }

        a.highestBid = msg.value;
        a.highestBidder = msg.sender;

        if (a.endTime - block.timestamp < EXTENSION_WINDOW) {
            a.endTime += EXTENSION_DURATION;
        }

        emit BidPlaced1155(auctionId, msg.sender, msg.value, a.endTime);
    }

    function settleAuction1155(uint256 auctionId) external nonReentrant whenNotPaused whenGlobalNotPaused {
        Auction1155 memory a = auctions1155[auctionId];

        require(a.endTime != 0, "Auction missing");
        require(block.timestamp >= a.endTime, "Not ended");

        delete auctions1155[auctionId];

        if (a.highestBidder == address(0)) {
            IERC1155(a.nft).safeTransferFrom(address(this), a.seller, a.tokenId, a.amount, "");

            emit AuctionSettled1155(auctionId, address(0), 0);
            return;
        }

        _handlePayment(a.nft, a.tokenId, a.seller, a.highestBidder, a.highestBid);

        IERC1155(a.nft).safeTransferFrom(address(this), a.highestBidder, a.tokenId, a.amount, "");

        emit AuctionSettled1155(auctionId, a.highestBidder, a.highestBid);
    }

    function cancelAuction1155(uint256 auctionId) external nonReentrant {
        Auction1155 memory a = auctions1155[auctionId];

        require(a.seller == msg.sender, "Not seller");
        require(a.highestBid == 0, "Already bid");

        delete auctions1155[auctionId];

        IERC1155(a.nft).safeTransferFrom(address(this), msg.sender, a.tokenId, a.amount, "");

        emit AuctionCancelled1155(auctionId);
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
        override(IERC165, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                        Helper Function
    //////////////////////////////////////////////////////////////*/

    function _requireERC1155(address nft) internal view {
        require(IERC165(nft).supportsInterface(type(IERC1155).interfaceId), "Not ERC1155");
    }

    /*//////////////////////////////////////////////////////////////
                        STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    uint256[50] private __gapV3;
}
