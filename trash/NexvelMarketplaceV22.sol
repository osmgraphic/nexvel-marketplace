// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                    NEXVEL MARKETPLACE V2
                    (HARDENED AUCTION UPGRADE)
//////////////////////////////////////////////////////////////*/

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {NexvelMarketplace} from "./NexvelMarketplace.sol";

/// @custom:oz-upgrades-from NexvelMarketplace
contract NexvelMarketplaceV2 is NexvelMarketplace, IERC721Receiver {

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR (DISABLED)
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                        INITIALIZER V2
    //////////////////////////////////////////////////////////////*/

    function initializeV2() external reinitializer(2) {
        // Version bump only — DO NOT reinitialize EIP712
    }

    /*//////////////////////////////////////////////////////////////
                        AUCTION STORAGE
    //////////////////////////////////////////////////////////////*/

    struct Auction {
        uint256 id;
        address seller;
        uint256 minPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
    }

    // nft => tokenId => Auction
    uint256 public nextAuctionId;
    mapping(uint256 => Auction) public auctionsById;
    mapping(address => mapping(uint256 => uint256)) public auctionIdByNFT;
    mapping(address => mapping(uint256 => Auction)) public auctions;
    mapping(address => uint256) public pendingRefunds;

    uint256 public constant MIN_BID_INCREMENT_BPS = 250; // 2.5%
    uint256 public constant EXTENSION_WINDOW = 10 minutes;
    uint256 public constant EXTENSION_DURATION = 10 minutes;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 minPrice,
        uint256 endTime
    );

    event BidPlaced(
        uint256 indexed auctionId,
        address indexed nft,
        uint256 indexed tokenId,
        address bidder,
        uint256 amount,
        uint256 newEndTime
    );

    event AuctionSettled(
        uint256 indexed auctionId,
        address indexed nft,
        uint256 indexed tokenId,
        address winner,
        uint256 amount
    );

    event AuctionCancelled(
        address indexed nft,
        uint256 indexed tokenId
    );

    /*//////////////////////////////////////////////////////////////
                        CREATE AUCTION
    //////////////////////////////////////////////////////////////*/

    function createAuction(
        address nft,
        uint256 tokenId,
        uint256 minPrice,
        uint256 duration
    )
        external
        nonReentrant
        whenNotPaused
        whenGlobalNotPaused
    {
        require(minPrice > 0, "Min price zero");
        require(duration >= 1 hours, "Duration too short");
        require(allowedCollections[nft], "Collection not allowed");
        _requireERC721(nft);
        require(auctions[nft][tokenId].endTime == 0, "Auction exists");

        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);

        uint256 endTime = block.timestamp + duration;

        uint256 auctionId = nextAuctionId++;

        auctionsById[auctionId] = Auction({
            id: auctionId,
            seller: msg.sender,
            minPrice: minPrice,
            highestBid: 0,
            highestBidder: address(0),
            endTime: endTime
        });
        
        auctionIdByNFT[nft][tokenId] = auctionId;

        emit AuctionCreated(
            auctionId,
            nft,
            tokenId,
            auctionsById[auctionId].seller,
            uint256(auctionsById[auctionId].minPrice),
            uint256(auctionsById[auctionId].endTime)
        );
    }

    /*//////////////////////////////////////////////////////////////
                            BID
    //////////////////////////////////////////////////////////////*/

    function bid(address nft, uint256 tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
        whenGlobalNotPaused
    {
        Auction storage auction = auctions[nft][tokenId];
    
        require(auction.endTime != 0, "Auction missing");
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.sender != auction.seller, "Seller cannot bid");
        require(msg.value <= maxTradeValue, "Trade limit exceeded");
    
        uint256 minBid = auction.highestBid == 0
            ? auction.minPrice
            : (auction.highestBid * (10_000 + MIN_BID_INCREMENT_BPS)) / 10_000;
    
        require(msg.value > minBid, "Bid too low");
    
        if (auction.highestBidder != address(0)) {
            pendingRefunds[auction.highestBidder] += auction.highestBid;
        }
    
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
    
        if (auction.endTime - block.timestamp < EXTENSION_WINDOW) {
            auction.endTime += EXTENSION_DURATION;
        }
    
        emit BidPlaced(auction.id, nft, tokenId, msg.sender, msg.value, auction.endTime);
    }


    /*//////////////////////////////////////////////////////////////
                        SETTLE AUCTION
    //////////////////////////////////////////////////////////////*/

    function settleAuction(address nft, uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        whenGlobalNotPaused
    {
        Auction memory auction = auctions[nft][tokenId];
    
        require(auction.endTime != 0, "Auction missing");
        require(block.timestamp >= auction.endTime, "Auction not ended");
    
        delete auctions[nft][tokenId];
    
        if (auction.highestBidder == address(0)) {
            IERC721(nft).safeTransferFrom(
                address(this),
                auction.seller,
                tokenId
            );
            emit AuctionSettled(auction.id, nft, tokenId, address(0), 0);
            return;
        }
    
        _handlePayment(
            nft,
            tokenId,
            auction.seller,
            auction.highestBidder,   // ✅ CORRECT BUYER
            auction.highestBid
        );
    
        IERC721(nft).safeTransferFrom(
            address(this),
            auction.highestBidder,
            tokenId
        );
    
        emit AuctionSettled(
            auction.id,
            nft,
            tokenId,
            auction.highestBidder,
            auction.highestBid
        );
    }


    /*//////////////////////////////////////////////////////////////
                        CANCEL AUCTION
    //////////////////////////////////////////////////////////////*/

    function cancelAuction(address nft, uint256 tokenId)
        external
        nonReentrant
    {
        Auction memory auction = auctions[nft][tokenId];

        require(auction.seller == msg.sender, "Not seller");
        require(auction.highestBid == 0, "Already bid");

        delete auctions[nft][tokenId];

        IERC721(nft).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        emit AuctionCancelled(nft, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC721 RECEIVER
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override(IERC721Receiver, NexvelMarketplace) returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /*//////////////////////////////////////////////////////////////
                        Withdraw Refund
    //////////////////////////////////////////////////////////////*/

    function withdrawRefund() external nonReentrant {
        uint256 amount = pendingRefunds[msg.sender];
        require(amount > 0, "No refund");
    
        pendingRefunds[msg.sender] = 0;
    
        (bool ok,) = payable(msg.sender).call{value: amount}("");
        require(ok, "Withdraw failed");
    }

    function _requireERC721(address nft) internal view {
        require(
            IERC165(nft).supportsInterface(type(IERC721).interfaceId),
            "Not ERC721"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    uint256[50] private __gapV2;
}
