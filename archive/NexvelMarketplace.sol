// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IMarketplaceAddressRegistry} from "./interfaces/IMarketplaceAddressRegistry.sol";
import {NexvelSecurityUpgradeable} from "./security/NexvelSecurityUpgradeable.sol";
import {NexvelERC721} from "./NexvelERC721.sol";
import {INexvelERC721} from "./interfaces/INexvelERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NexvelMarketplace is Initializable, EIP712Upgradeable, UUPSUpgradeable, NexvelSecurityUpgradeable {
    using SafeERC20 for IERC20;

    uint256 private constant BPS = 10_000;

    uint96 public marketplaceFeeBps;
    address public marketplaceFeeRecipient;
    uint256 public maxTradeValue;

    struct Listing {
        uint256 id;
        address seller;
        uint256 price;
        address paymentToken; // address(0) = ETH
        bool active;
        uint256 expiry;
    }

    uint256 public nextListingId;
    mapping(uint256 => Listing) public listingsById;
    mapping(address => mapping(uint256 => uint256)) public listingIdByNFT;
    mapping(address => mapping(uint256 => Listing)) public listings;
    mapping(address => bool) public allowedCollections;
    mapping(address => bool) public allowedPaymentTokens;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Listed(
        uint256 indexed listingId,
        address indexed nft,
        uint256 indexed tokenId,
        address seller,
        uint256 price,
        address paymentToken,
        bool isERC20
    );
    event ListingCancelled(address indexed nft, uint256 indexed tokenId, address indexed seller);
    event EmergencyListingCancelled(address indexed nft, uint256 indexed tokenId, address indexed seller);

    event CollectionUpdated(address indexed nft, bool allowed);
    event PaymentTokenUpdated(address indexed token, bool allowed);
    event RegistryUpdated(address indexed newRegistry);

    event MarketplaceFeeUpdated(uint96 oldFee, uint96 newFee);
    event MarketplaceFeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event MaxTradeValueUpdated(uint256 oldValue, uint256 newValue);

    event PlatformFeePaid(address indexed payer, uint256 amount);
    event RoyaltyPaid(address indexed receiver, uint256 amount);
    event SellerPaid(address indexed seller, uint256 amount);

    event SaleBreakdown(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed buyer,
        address seller,
        uint256 totalPrice,
        uint256 royaltyAmount,
        uint256 platformFee
    );

    event PriceUpdated(uint256 indexed listingId, uint256 oldPrice, uint256 newPrice);

    /*//////////////////////////////////////////////////////////////
                                INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address admin_,
        address operator_,
        address registry_,
        address[] calldata creators_,
        address marketplaceFeeRecipient_,
        uint96 marketplaceFeeBps_,
        uint256 maxTradeValue_
    ) external initializer {
        require(admin_ != address(0), "Admin zero");
        require(marketplaceFeeRecipient_ != address(0), "Fee recipient zero");
        require(marketplaceFeeBps_ <= 1000, "Fee too high");
        require(registry_ != address(0), "Registry zero");

        registry = IMarketplaceAddressRegistry(registry_);

        __EIP712_init("NexvelMarketplace", "1");
        __UUPSUpgradeable_init();
        __NexvelSecurity_init(admin_, operator_, registry_, creators_);

        marketplaceFeeBps = marketplaceFeeBps_;
        marketplaceFeeRecipient = marketplaceFeeRecipient_;
        maxTradeValue = maxTradeValue_;
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    function setMarketplaceFee(uint96 newFee) external onlyRole(ADMIN_ROLE) {
        require(newFee <= 1000, "Fee too high");
        emit MarketplaceFeeUpdated(marketplaceFeeBps, newFee);
        marketplaceFeeBps = newFee;
    }

    function setMarketplaceFeeRecipient(address newRecipient) external onlyRole(ADMIN_ROLE) {
        require(newRecipient != address(0), "Zero address");
        emit MarketplaceFeeRecipientUpdated(marketplaceFeeRecipient, newRecipient);
        marketplaceFeeRecipient = newRecipient;
    }

    function setMaxTradeValue(uint256 newValue) external onlyRole(ADMIN_ROLE) {
        emit MaxTradeValueUpdated(maxTradeValue, newValue);
        maxTradeValue = newValue;
    }

    function setAllowedPaymentToken(address token, bool allowed) external onlyRole(ADMIN_ROLE) {
        require(token != address(0), "Zero address");
        allowedPaymentTokens[token] = allowed;
        emit PaymentTokenUpdated(token, allowed);
    }

    function setAllowedCollection(address nft, bool allowed) external onlyRole(ADMIN_ROLE) {
        require(nft != address(0), "Zero address");
        require(
            IERC165(nft).supportsInterface(type(IERC721).interfaceId)
                || IERC165(nft).supportsInterface(type(IERC1155).interfaceId),
            "Unsupported NFT"
        );
        allowedCollections[nft] = allowed;
        emit CollectionUpdated(nft, allowed);
    }

    function updatePrice(address nft, uint256 tokenId, uint256 newPrice) external {
        uint256 listingId = listingIdByNFT[nft][tokenId];
        Listing storage listing = listingsById[listingId];

        require(listing.seller == msg.sender, "Not seller");
        require(newPrice > 0, "Invalid price");

        uint256 oldPrice = listing.price;
        listing.price = newPrice;

        emit PriceUpdated(listingId, oldPrice, newPrice);
    }

    /*//////////////////////////////////////////////////////////////
                        STANDARD LISTING
    //////////////////////////////////////////////////////////////*/

    function list(address nft, uint256 tokenId, uint256 price, address paymentToken, bool isERC20, uint256 expiry)
        external
        nonReentrant
        whenNotPaused
        whenGlobalNotPaused
    {
        require(price > 0, "Price zero");
        require(price <= maxTradeValue, "Price too high");
        require(allowedCollections[nft], "Collection blocked");
        require(expiry > block.timestamp, "Invalid expiry");

        // ⭐ NEW — payment validation
        if (paymentToken != address(0)) {
            require(allowedPaymentTokens[paymentToken], "Payment token not allowed");
        }

        require(listings[nft][tokenId].seller == address(0), "Already listed");

        IERC721 token = IERC721(nft);
        require(token.ownerOf(tokenId) == msg.sender, "Not owner");

        token.safeTransferFrom(msg.sender, address(this), tokenId);

        uint256 listingId = nextListingId++;

        listingsById[listingId] = Listing({
            id: listingId, seller: msg.sender, price: price, paymentToken: paymentToken, active: true, expiry: expiry
        });

        listingIdByNFT[nft][tokenId] = listingId;

        emit Listed(listingId, nft, tokenId, msg.sender, price, paymentToken, isERC20);
    }

    function buy(address nft, uint256 tokenId) external payable nonReentrant whenNotPaused whenGlobalNotPaused {
        Listing memory listing = listings[nft][tokenId];

        require(listing.price > 0, "Not listed");
        require(msg.sender != listing.seller, "Self purchase");
        require(msg.value == listing.price, "Wrong price");
        require(block.timestamp <= listing.expiry, "Listing expired");

        delete listings[nft][tokenId];

        _handlePayment(nft, tokenId, listing.seller, msg.sender, msg.value);

        IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        emit SaleBreakdown(
            nft,
            tokenId,
            msg.sender,
            listing.seller,
            listing.price,
            0, // royalty and platform fee are included in the _handlePayment events
            0
        );
    }

    /*//////////////////////////////////////////////////////////////
                        Buy With ERC20
    //////////////////////////////////////////////////////////////*/

    function buyWithERC20(address nft, uint256 tokenId, uint256 expectedPrice)
        external
        nonReentrant
        whenNotPaused
        whenGlobalNotPaused
    {
        Listing memory listing = listings[nft][tokenId];

        require(listing.price <= maxTradeValue, "Trade limit exceeded");
        require(listing.price > 0, "Not listed");
        require(listing.active, "Not listed");
        require(listing.paymentToken != address(0), "ETH listing");
        require(msg.sender != listing.seller, "Seller cannot buy");
        require(expectedPrice == listing.price, "Price mismatch");

        require(allowedPaymentTokens[listing.paymentToken], "Token not allowed");

        require(IERC721(nft).ownerOf(tokenId) == address(this), "Marketplace not owner");

        IERC20 token = IERC20(listing.paymentToken);

        // ✅ pull funds first
        token.safeTransferFrom(msg.sender, address(this), listing.price);

        // ✅ clear listing
        delete listings[nft][tokenId];

        // ✅ handle payment splits
        _handlePaymentERC20(nft, tokenId, listing.seller, msg.sender, listing.paymentToken, listing.price);

        // ✅ transfer NFT
        IERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        emit SaleBreakdown(
            nft,
            tokenId,
            msg.sender,
            listing.seller,
            listing.price,
            0, // royalty and platform fee are included in the _handlePaymentERC20 events
            0
        );
    }

    /*//////////////////////////////////////////////////////////////
                        PAYMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _handlePayment(address nft, uint256 tokenId, address seller, address buyer, uint256 amount) internal {
        uint256 platformFee = (amount * marketplaceFeeBps) / BPS;
        uint256 remaining = amount - platformFee;
        uint256 royaltyAmount = 0;

        try IERC2981(nft).royaltyInfo(tokenId, amount) returns (address receiver, uint256 royalty) {
            if (royalty > 0 && receiver != address(0)) {
                require(royalty <= remaining, "Royalty exceeds seller amount");
                royaltyAmount = royalty;
                remaining -= royalty;

                _sendETH(receiver, royalty);
                emit RoyaltyPaid(receiver, royalty);
            }
        } catch {}

        _sendETH(seller, remaining);
        emit SellerPaid(seller, remaining);

        _sendETH(marketplaceFeeRecipient, platformFee);
        emit PlatformFeePaid(buyer, platformFee);

        emit SaleBreakdown(nft, tokenId, buyer, seller, amount, royaltyAmount, platformFee);
    }

    function _handlePaymentERC20(
        address nft,
        uint256 tokenId,
        address seller,
        address buyer,
        address token,
        uint256 amount
    ) internal {
        uint256 platformFee = (amount * marketplaceFeeBps) / BPS;
        uint256 remaining = amount - platformFee;
        uint256 royaltyAmount = 0;

        try IERC2981(nft).royaltyInfo(tokenId, amount) returns (address receiver, uint256 royalty) {
            if (royalty > 0 && receiver != address(0)) {
                require(royalty <= remaining, "Royalty exceeds seller amount");
                royaltyAmount = royalty;
                remaining -= royalty;

                IERC20(token).safeTransfer(receiver, royalty);
                emit RoyaltyPaid(receiver, royalty);
            }
        } catch {}

        IERC20(token).safeTransfer(seller, remaining);
        emit SellerPaid(seller, remaining);

        IERC20(token).safeTransfer(marketplaceFeeRecipient, platformFee);
        emit PlatformFeePaid(buyer, platformFee);

        emit SaleBreakdown(nft, tokenId, buyer, seller, amount, royaltyAmount, platformFee);
    }

    function _sendETH(address to, uint256 amount) internal {
        if (amount == 0) return;
        (bool ok,) = to.call{value: amount}("");
        require(ok, "ETH transfer failed");
    }

    /*//////////////////////////////////////////////////////////////
                        UUPS AUTH
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyRole(ADMIN_ROLE) {}

    /*//////////////////////////////////////////////////////////////
                        Cancel listing (emergency)
    //////////////////////////////////////////////////////////////*/

    function cancelListing(address token, uint256 tokenId) external nonReentrant {
        Listing memory listing = listings[token][tokenId];

        require(listing.active, "Not listed");
        require(listing.seller == msg.sender, "Not seller");
        require(IERC721(token).ownerOf(tokenId) == address(this), "Marketplace not owner");

        delete listings[token][tokenId];

        IERC721(token).safeTransferFrom(address(this), listing.seller, tokenId);

        emit ListingCancelled(token, tokenId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                    emergencyCancellisting (emergency)
    //////////////////////////////////////////////////////////////*/

    function emergencyCancelListing(address token, uint256 tokenId) external onlyAdmin nonReentrant {
        Listing memory listing = listings[token][tokenId];

        require(listing.active, "Not listed");
        require(IERC721(token).ownerOf(tokenId) == address(this), "Marketplace not owner");

        delete listings[token][tokenId];

        IERC721(token).safeTransferFrom(address(this), listing.seller, tokenId);

        emit EmergencyListingCancelled(token, tokenId, listing.seller);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC721 RECEIVER
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(address, address, uint256, bytes calldata) external pure virtual returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    uint256[50] private __gap;

    receive() external payable {}
    fallback() external payable {}
}
