// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                        IMPORTS
//////////////////////////////////////////////////////////////*/

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {NexvelNFTFactory} from "./NexvelNFTFactory.sol";
import {INexvelERC1155} from "./interfaces/INexvelERC1155.sol";
import {INexvelERC721} from "./interfaces/INexvelERC721.sol";
import {NexvelSecurityUpgradeable} from "./security/NexvelSecurityUpgradeable.sol";
import {NexvelERC721A} from "./NexvelERC721A.sol";
import {IMarketplaceAddressRegistry} from "./interfaces/IMarketplaceAddressRegistry.sol";

/*//////////////////////////////////////////////////////////////
                    NEXVEL LAUNCHPAD
//////////////////////////////////////////////////////////////*/

contract NexvelLaunchpad is Initializable, EIP712Upgradeable, UUPSUpgradeable, NexvelSecurityUpgradeable {
    using SafeERC20 for IERC20;
    INexvelERC1155 public nexvel1155;
    bool nftLocked;

    uint256 private constant BPS = 10_000;

    /*//////////////////////////////////////////////////////////////
                        ENUMS
    //////////////////////////////////////////////////////////////*/

    enum SaleType {
        Public,
        Whitelist,
        Signature
    }

    enum TokenType {
        ERC721,
        ERC1155,
        ERC721A
    }

    enum SaleStatus {
        Active,
        Successful,
        Failed,
        Cancelled
    }

    /*//////////////////////////////////////////////////////////////
                        SALE STRUCT
    //////////////////////////////////////////////////////////////*/

    struct Sale {
        address creator;
        TokenType tokenType;
        address nft;
        uint256 tokenId; // ERC1155 only
        address paymentToken; // address(0) = ETH
        uint256 price;
        uint256 maxSupply;
        uint256 sold;
        uint256 maxPerWallet;
        uint256 startTime;
        uint256 endTime;
        uint96 royaltyBps;
        address royaltyReceiver;
        uint256 softCap;
        SaleType saleType;
        bytes32 merkleRoot;
        SaleStatus status;
        uint256 totalRaised;
        bool fundsClaimed;
        string uri;
        uint256 creatorNonce;
        bool nftLocked; // invalidates old sales
    }

    struct SaleVoucher {
        uint256 saleId;
        address buyer;
        uint256 price;
        uint256 maxQuantity;
        uint256 maxSpend; // 🔐 NEW (ERC20 cap)
        uint256 nonce;
        uint256 deadline;
    }

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 public saleCount;
    uint256 public activeSaleCount;
    // fees
    address public launchpadFeeRecipient;
    uint96 public launchpadFeeBps;
    NexvelNFTFactory public factory;
    address public backendSigner;

    /*//////////////////////////////////////////////////////////////
                        Mappings
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 => Sale) public sales;
    mapping(uint256 => mapping(address => uint256)) public userPurchased;
    mapping(uint256 => mapping(address => uint256)) public userPaid;
    mapping(uint256 => mapping(address => uint256)) public signaturePurchased;

    // SALE-SCOPED nonce protection
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) public usedNonce;

    mapping(address => uint256) public creatorNonce;
    mapping(address => bool) public creatorPaused;
    mapping(address => bool) public allowedPaymentTokens;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    // Sale lifecycle
    event SaleCreated(
        uint256 indexed saleId,
        address indexed creator,
        address nft,
        uint256 tokenId,
        SaleType saleType,
        uint256 price,
        uint256 maxSupply,
        uint256 startTime,
        uint256 endTime
    );

    event SaleFinalized(uint256 indexed saleId, SaleStatus status, uint256 totalRaised);
    event SaleCancelled(uint256 indexed saleId, address indexed cancelledBy);
    // Purchases
    event Purchased(uint256 indexed saleId, address indexed buyer, uint256 quantity, address paymentToken, uint256 totalPaid);
    event SignaturePurchased(uint256 indexed saleId, address indexed buyer, uint256 quantity, address paymentToken, uint256 totalPaid);
    // Claims
    event NFTClaimed(uint256 indexed saleId, address indexed buyer, uint256 quantity);
    event FundsClaimed(uint256 indexed saleId, address indexed creator, uint256 creatorAmount, uint256 platformFee);
    // Refunds
    event Refunded(uint256 indexed saleId, address indexed buyer, uint256 amount);
    // Admin / config
    event PaymentTokenUpdated(address indexed token, bool allowed);
    event BackendSignerUpdated(address indexed oldSigner, address indexed newSigner);
    event LaunchpadFeeUpdated(uint96 oldFee, uint96 newFee);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event RegistryUpdated(address indexed newRegistry);
    event NFTDeployed(uint256 indexed saleId, address nft);

    /*//////////////////////////////////////////////////////////////
                        SIGNATURE CONSTANTS
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant SIGNATURE_TYPEHASH = keccak256(
        "SaleVoucher(uint256 saleId,address buyer,uint256 price,uint256 maxQuantity,uint256 maxSpend,uint256 nonce,uint256 deadline,address contract)"
    );

    /*//////////////////////////////////////////////////////////////
                        INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address admin_,
        address operator_,
        address registry_,
        address[] calldata creators_,
        address launchpadFeeRecipient_,
        uint96 launchpadFeeBps_
    ) external initializer {
        require(registry_ != address(0), "Registry zero");
        require(launchpadFeeRecipient_ != address(0), "Launchpad fee recipient zero");
        require(launchpadFeeBps_ <= 1_000, "Launchpad fee too high");

        registry = IMarketplaceAddressRegistry(registry_);

        __EIP712_init("NexvelLaunchpad", "1");
        __UUPSUpgradeable_init();
        __NexvelSecurity_init(admin_, operator_, registry_, creators_);

        launchpadFeeRecipient = launchpadFeeRecipient_;
        launchpadFeeBps = launchpadFeeBps_;
    }

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                        REGISTRY ADMIN
    //////////////////////////////////////////////////////////////*/

    function setRegistry(address newRegistry) external onlyAdmin {
        require(newRegistry != address(0), "Registry zero");
        registry = IMarketplaceAddressRegistry(newRegistry);
        emit RegistryUpdated(newRegistry);
    }

    function setFactory(address factoryAddress) external onlyAdmin {
        require(factoryAddress != address(0), "Invalid factory");
        factory = NexvelNFTFactory(factoryAddress);
    }

    /*//////////////////////////////////////////////////////////////
                        FACTORY / ERC1155 RESOLVERS
    //////////////////////////////////////////////////////////////*/

    function _factory() internal view returns (NexvelNFTFactory) {
        return NexvelNFTFactory(registry.nftFactory());
    }

    function _erc1155() internal view returns (INexvelERC1155) {
        return INexvelERC1155(registry.erc1155());
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL VALIDATION
    //////////////////////////////////////////////////////////////*/
    function _validateSale(Sale storage sale, uint256 quantity) internal view {
        // Creator has invalidated old sales
        require(sale.creatorNonce == creatorNonce[sale.creator], "Sale invalidated by creator");

        // Supply safety
        require(sale.sold + quantity <= sale.maxSupply, "Max supply exceeded");
    }

    function _verifyWhitelist(bytes32 merkleRoot, address user, bytes32[] calldata proof) internal pure {
        // If no whitelist is set, allow everyone
        if (merkleRoot == bytes32(0)) return;

        bytes32 leaf = keccak256(abi.encodePacked(user));

        require(MerkleProof.verify(proof, merkleRoot, leaf), "Not whitelisted");
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN CONTROLS
    //////////////////////////////////////////////////////////////*/

    function setBackendSigner(address signer) external onlyAdmin {
        require(signer != address(0), "Invalid signer");

        address oldSigner = backendSigner;
        backendSigner = signer;
        
        emit BackendSignerUpdated(oldSigner, signer);
    }

    function setPaymentToken(address token, bool allowed) external onlyAdmin {
        allowedPaymentTokens[token] = allowed;

        emit PaymentTokenUpdated(token, allowed);
    }

    function setPlatformFee(uint96 newFee) external onlyAdmin {
        require(newFee <= 1_000, "Fee too high");
        require(activeSaleCount == 0, "Active sales exist");

        uint96 oldFee = launchpadFeeBps;
        launchpadFeeBps = newFee;

        emit LaunchpadFeeUpdated(oldFee, newFee);
    }

    function setFeeRecipient(address newRecipient) external onlyAdmin {
        require(newRecipient != address(0), "Invalid recipient");
        require(activeSaleCount == 0, "Active sales exist");

        address oldRecipient = launchpadFeeRecipient;
        launchpadFeeRecipient = newRecipient;

        emit FeeRecipientUpdated(oldRecipient, newRecipient);
    }

    /*//////////////////////////////////////////////////////////////
                              tryPermit
    //////////////////////////////////////////////////////////////*/

    function _tryPermit(address token, address owner, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        internal
    {
        // If token is zero address (ETH), skip
        if (token == address(0)) return;

        // Try permit — if token doesn't support it, catch and continue
        try IERC20Permit(token).permit(owner, address(this), value, deadline, v, r, s) {
        // permit succeeded
        }
            catch {
            // permit not supported or failed → ignore
        }
    }

    /*//////////////////////////////////////////////////////////////
                        CREATE SALE
    //////////////////////////////////////////////////////////////*/

    function createSale(Sale calldata s) external onlyCreator {
        require(s.nft != address(0), "Invalid NFT");
        require(s.startTime < s.endTime, "Invalid time");
        require(s.startTime >= block.timestamp, "Start in past");
        require(s.maxSupply > 0, "Zero supply");
        require(s.maxPerWallet > 0, "Invalid wallet limit");
        require(s.price > 0, "Invalid price");
        require(s.softCap > 0, "Invalid softcap");
        require(!s.nftLocked, "NFT already locked");
        require(s.royaltyBps <= 1000, "Royalty too high");

        address receiver = s.royaltyReceiver == address(0) ? msg.sender : s.royaltyReceiver;

        if (s.paymentToken != address(0)) {
            require(allowedPaymentTokens[s.paymentToken], "Token not allowed");
        }

        sales[++saleCount] = Sale({
            creator: msg.sender,
            tokenType: s.tokenType,
            nft: s.nft,
            tokenId: s.tokenId,
            paymentToken: s.paymentToken,
            price: s.price,
            maxSupply: s.maxSupply,
            sold: 0,
            maxPerWallet: s.maxPerWallet,
            startTime: s.startTime,
            endTime: s.endTime,
            royaltyBps: s.royaltyBps,
            royaltyReceiver: receiver,
            softCap: s.softCap,
            saleType: s.saleType,
            merkleRoot: s.merkleRoot,
            status: SaleStatus.Active,
            totalRaised: 0,
            fundsClaimed: false,
            uri: "",
            creatorNonce: creatorNonce[msg.sender],
            nftLocked: true
        });

        activeSaleCount++;

        emit SaleCreated(
            saleCount, msg.sender, s.nft, s.tokenId, s.saleType, s.price, s.maxSupply, s.startTime, s.endTime
        );
    }

    /*//////////////////////////////////////////////////////////////
                        BUY (PUBLIC / WHITELIST)
    //////////////////////////////////////////////////////////////*/

    function buy(uint256 saleId, uint256 amount, bytes32[] calldata proof)
        external
        payable
        nonReentrant
        whenGlobalNotPaused
    {
        require(amount > 0, "Invalid quantity");
        Sale storage sale = sales[saleId];

        require(sale.saleType != SaleType.Signature, "Use signature buy");
        require(sale.status == SaleStatus.Active, "Inactive");
        require(block.timestamp >= sale.startTime && block.timestamp <= sale.endTime, "Not live");
        require(!creatorPaused[sale.creator], "Creator paused");
        require(sale.sold + amount <= sale.maxSupply, "Supply exceeded");

        // Sale-level validation (creator nonce + supply)
        _validateSale(sale, amount);

        // Wallet limit
        uint256 already = userPurchased[saleId][msg.sender];
        require(already + amount <= sale.maxPerWallet, "Wallet limit");

        // Whitelist check (delegated)
        if (sale.saleType == SaleType.Whitelist) {
            _verifyWhitelist(sale.merkleRoot, msg.sender, proof);
        }

        // Payment
        uint256 total = sale.price * amount;

        if (sale.paymentToken == address(0)) {
            require(msg.value == total, "Wrong ETH");
        } else {
            IERC20(sale.paymentToken).safeTransferFrom(msg.sender, address(this), total);
        }

        // Accounting
        unchecked {
            sale.sold += amount;
            sale.totalRaised += total;
        }
        
        userPurchased[saleId][msg.sender] += amount;
        userPaid[saleId][msg.sender] += total;

        emit Purchased(saleId, msg.sender, amount, sale.paymentToken, total);
    }

    /*//////////////////////////////////////////////////////////////
                       BUY WITH SIGNATURE
    //////////////////////////////////////////////////////////////*/

    function buyWithSignatureAndPermit(
        SaleVoucher calldata v,
        uint256 quantity,
        bytes calldata sig,
        uint256 permitValue,
        uint256 permitDeadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external payable nonReentrant whenGlobalNotPaused {
        Sale storage sale = sales[v.saleId];

        require(sale.paymentToken != address(0), "ETH sale");

        if (permitDeadline != 0) {
            try IERC20Permit(sale.paymentToken)
                .permit(msg.sender, address(this), permitValue, permitDeadline, permitV, permitR, permitS) {}
                catch {}

            uint256 allowance = IERC20(sale.paymentToken).allowance(msg.sender, address(this));

            uint256 total = sale.price * quantity;
            require(allowance >= total, "Permit/allowance insufficient");
        }

        _buyWithSignature(v, quantity, sig);
    }

    function _buyWithSignature(SaleVoucher calldata v, uint256 quantity, bytes calldata sig) internal {
        require(msg.sender == v.buyer, "Not buyer");
        require(quantity > 0, "Invalid quantity");
        require(block.timestamp <= v.deadline, "Expired");
        require(!usedNonce[v.saleId][v.buyer][v.nonce], "Nonce used");
        usedNonce[v.saleId][v.buyer][v.nonce] = true;

        Sale storage sale = sales[v.saleId];

        require(sale.saleType == SaleType.Signature, "Not signature sale");
        require(sale.status == SaleStatus.Active, "Inactive");
        require(block.timestamp >= sale.startTime, "Not started");
        require(block.timestamp <= sale.endTime, "Ended");
        require(sale.sold + quantity <= sale.maxSupply, "Supply exceeded");

        _validateSale(sale, quantity);

        uint256 alreadySigBought = signaturePurchased[v.saleId][msg.sender];

        require(alreadySigBought + quantity <= v.maxQuantity, "Signature max exceeded");

        require(v.price == sale.price, "Price mismatch");

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    SIGNATURE_TYPEHASH,
                    v.saleId,
                    v.buyer,
                    v.price,
                    v.maxQuantity,
                    v.maxSpend,
                    v.nonce,
                    v.deadline,
                    address(this) // 🔥 ADD
                )
            )
        );

        require(ECDSA.recover(digest, sig) == backendSigner, "Invalid signer");

        uint256 total = sale.price * quantity;

        if (sale.paymentToken != address(0)) {
            uint256 newTotalSpend = userPaid[v.saleId][msg.sender] + total;
            require(newTotalSpend <= v.maxSpend, "ERC20 spend cap exceeded");
        }

        if (sale.paymentToken == address(0)) {
            require(msg.value == total, "Wrong ETH");
        } else {
            require(allowedPaymentTokens[sale.paymentToken], "Token not allowed");

            IERC20(sale.paymentToken).safeTransferFrom(msg.sender, address(this), total);
        }
        
        unchecked {
            sale.sold += quantity;
            sale.totalRaised += total;
        }
        
        signaturePurchased[v.saleId][msg.sender] += quantity;
        userPurchased[v.saleId][msg.sender] += quantity;
        userPaid[v.saleId][msg.sender] += total;

        emit SignaturePurchased(v.saleId, msg.sender, quantity, sale.paymentToken, total);
    }

    /*//////////////////////////////////////////////////////////////
                        FINALIZE
    //////////////////////////////////////////////////////////////*/

    function finalizeSale(uint256 saleId) external {
        Sale storage sale = sales[saleId];

        require(block.timestamp > sale.endTime, "Not ended");
        require(sale.status == SaleStatus.Active, "Finalized");

        sale.status = sale.totalRaised >= sale.softCap ? SaleStatus.Successful : SaleStatus.Failed;
        
        require(activeSaleCount > 0, "Invalid state");
        activeSaleCount--;

        emit SaleFinalized(saleId, sale.status, sale.totalRaised);
    }

    /*//////////////////////////////////////////////////////////////
                        CLAIM NFT
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        CLAIM NFT
    //////////////////////////////////////////////////////////////*/

    function claimNft(uint256 saleId) external nonReentrant whenNotPaused whenGlobalNotPaused {
        Sale storage sale = sales[saleId];
        require(sale.status == SaleStatus.Successful, "Sale not successful");

        uint256 amount = userPurchased[saleId][msg.sender];
        require(amount > 0, "Nothing to claim");

        userPurchased[saleId][msg.sender] = 0;

        if (sale.tokenType == TokenType.ERC1155) {
            _erc1155().mintLaunchpad(msg.sender, sale.tokenId, amount, sale.uri);
        } else {
            INexvelERC721(sale.nft)
                .mintBatch721Launchpad(msg.sender, amount, sale.uri, sale.royaltyReceiver, sale.royaltyBps);
        }

        emit NFTClaimed(saleId, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        CLAIM FUNDS
    //////////////////////////////////////////////////////////////*/

    function claimFunds(uint256 saleId) external nonReentrant {
        Sale storage sale = sales[saleId];
        require(launchpadFeeRecipient != address(0), "Invalid fee recipient");
        require(sale.status == SaleStatus.Successful, "Not successful");
        require(msg.sender == sale.creator, "Not creator");
        require(!sale.fundsClaimed, "Already claimed");

        sale.fundsClaimed = true;

        uint256 fee = (sale.totalRaised * launchpadFeeBps) / BPS;
        uint256 creatorAmount = sale.totalRaised - fee;

        if (sale.paymentToken == address(0)) {
            require(address(this).balance >= sale.totalRaised, "Insufficient ETH");
            _safeTransferETH(launchpadFeeRecipient, fee);
            _safeTransferETH(sale.creator, creatorAmount);
        } else {
            require(
            IERC20(sale.paymentToken).balanceOf(address(this)) >= sale.totalRaised,
              "Insufficient token"
            );
            IERC20 token = IERC20(sale.paymentToken);
            token.safeTransfer(launchpadFeeRecipient, fee);
            token.safeTransfer(sale.creator, creatorAmount);
        }

        emit FundsClaimed(saleId, sale.creator, creatorAmount, fee);
    }

    /*//////////////////////////////////////////////////////////////
                        REFUND
    //////////////////////////////////////////////////////////////*/

    function refund(uint256 saleId) external nonReentrant {
        Sale storage sale = sales[saleId];

        require(sale.status == SaleStatus.Failed || sale.status == SaleStatus.Cancelled, "No refund");

        uint256 amount = userPaid[saleId][msg.sender];
        require(amount > 0, "Nothing");

        userPaid[saleId][msg.sender] = 0;

        if (sale.paymentToken == address(0)) {
            _safeTransferETH(msg.sender, amount);
        } else {
            IERC20(sale.paymentToken).safeTransfer(msg.sender, amount);
        }

        emit Refunded(saleId, msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL SALE (ADMIN)
    //////////////////////////////////////////////////////////////*/
    function cancelSale(uint256 saleId) external onlyAdmin {
        Sale storage sale = sales[saleId];

        require(sale.status == SaleStatus.Active, "Not active");
        require(block.timestamp < sale.endTime, "Sale ended");

        sale.status = SaleStatus.Cancelled;
        require(activeSaleCount > 0, "Invalid state");
        activeSaleCount--;
        emit SaleCancelled(saleId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL SALE (CREATOR)
    //////////////////////////////////////////////////////////////*/
    function cancelMySale(uint256 saleId) external {
        Sale storage sale = sales[saleId];
    
        require(msg.sender == sale.creator, "Not creator");
        require(sale.status == SaleStatus.Active, "Not active");
        require(block.timestamp < sale.endTime, "Sale ended");
    
        require(sale.sold == 0, "Already funded"); // 🔥 CRITICAL FIX
    
        sale.status = SaleStatus.Cancelled;
    
        require(activeSaleCount > 0, "Invalid state");
        activeSaleCount--;
    
        emit SaleCancelled(saleId, msg.sender);
    }

    // Factory call from Launchpad
    function createSaleWithNft(
        TokenType tokenType,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        SaleType saleType,
        bytes32 merkleRoot,
        string calldata name_,
        string calldata symbol_,
        address operator_,
        address[] calldata creators_,
        uint256 maxSupply_
    ) external onlyCreator returns (uint256 saleId) {
        require(maxSupply_ > 0, "Invalid supply");
        require(price > 0, "Invalid price");
        require(startTime >= block.timestamp, "Start in past");
        require(startTime < endTime, "Invalid time");

        // Map Launchpad TokenType → Factory NFTType
        NexvelNFTFactory.NFTType nftType;

        if (tokenType == TokenType.ERC721) {
            nftType = NexvelNFTFactory.NFTType.ERC721;
        } else if (tokenType == TokenType.ERC721A) {
            nftType = NexvelNFTFactory.NFTType.ERC721A;
        } else {
            revert("Unsupported TokenType for factory");
        }

        // Store sale
        saleId = ++saleCount;

        // Deploy NFT contract via factory
        address nft = factory.createNFT(name_, symbol_, nftType, operator_, creators_, maxSupply_);

        emit NFTDeployed(saleId, nft);

        sales[saleId] = Sale({
            creator: msg.sender,
            tokenType: tokenType,
            nft: nft,
            tokenId: 0,
            paymentToken: address(0),
            price: price,
            maxSupply: maxSupply_,
            sold: 0,
            maxPerWallet: maxSupply_,
            startTime: startTime,
            endTime: endTime,
            royaltyBps: 0,
            royaltyReceiver: address(0),
            softCap: 0,
            saleType: saleType,
            merkleRoot: merkleRoot,
            status: SaleStatus.Active,
            totalRaised: 0,
            fundsClaimed: false,
            uri: "",
            creatorNonce: creatorNonce[msg.sender],
            nftLocked: false
        });

        activeSaleCount++;

        emit SaleCreated(saleId, msg.sender, nft, 0, saleType, price, maxSupply_, startTime, endTime);
    }

    /*//////////////////////////////////////////////////////////////
                        CREATOR CONTROLS
    //////////////////////////////////////////////////////////////*/

    function pauseMyLaunchpad() external {
        creatorPaused[msg.sender] = true;
    }

    function unpauseMyLaunchpad() external {
        creatorPaused[msg.sender] = false;
    }

    function cancelMyVouchers() external {
        creatorNonce[msg.sender]++;
    }

    /*//////////////////////////////////////////////////////////////
                            SAFE ETH
    //////////////////////////////////////////////////////////////*/

    function _safeTransferETH(address to, uint256 amount) internal {
        (bool ok,) = to.call{value: amount}("");
        require(ok, "ETH transfer failed");
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY
    //////////////////////////////////////////////////////////////*/

    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyAdmin {
        require(to != address(0), "Invalid recipient");
    
        if (token == address(0)) {
            _safeTransferETH(to, amount);
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    // Reject ETH Transfers
    receive() external payable {
        revert("Direct ETH disabled");
    }

    fallback() external payable {
        revert("Direct ETH disabled");
    }

    /*//////////////////////////////////////////////////////////////
                        UUPS AUTH
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /*//////////////////////////////////////////////////////////////
                        STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    uint256[50] private __gap;
}
