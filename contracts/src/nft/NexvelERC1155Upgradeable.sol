// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {ERC1155Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {
    ERC1155SupplyUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {ERC2981Upgradeable} from "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {IMarketplaceAddressRegistry} from "./interfaces/IMarketplaceAddressRegistry.sol";
import {NexvelSecurityUpgradeable} from "./security/NexvelSecurityUpgradeable.sol";

/*//////////////////////////////////////////////////////////////
                    NEXVEL ERC1155 (REGISTRY)
//////////////////////////////////////////////////////////////*/

contract NexvelERC1155Upgradeable is
    Initializable,
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    UUPSUpgradeable,
    NexvelSecurityUpgradeable,
    EIP712Upgradeable
{
    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant BPS = 10_000;
    uint256 internal constant MAX_ROYALTY_BPS = 1_000;

    /*//////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal _nextTokenId;

    mapping(uint256 => uint256) internal maxSupply;
    mapping(uint256 => string) internal _tokenURIs;
    mapping(uint256 => bool) internal _tokenExists;

    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public usedVouchers;
    mapping(uint256 => address) public creatorOf;

    /*//////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/
    event RoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 royaltyBps);

    event TokenCreated(
        uint256 indexed tokenId, uint256 maxSupply, string uri, address royaltyReceiver, uint96 royaltyBps
    );

    event CreatorSet(uint256 tokenId, address creator);
    event URISet(uint256 indexed tokenId, string uri);

    /*//////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(
        string calldata baseURI,
        address registry_,
        address admin_,
        address operator_,
        address[] calldata creators_
    ) external initializer {
        require(admin_ != address(0), "Admin zero");
        require(registry_ != address(0), "Registry zero");

        __ERC1155_init(baseURI);
        __ERC1155Supply_init();
        __ERC2981_init();
        __UUPSUpgradeable_init();
        __EIP712_init("NexvelERC1155", "1");

        registry = IMarketplaceAddressRegistry(registry_);

        __NexvelSecurity_init(admin_, operator_, registry_, creators_);

        _nextTokenId = 1;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                            UUPS
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    /*//////////////////////////////////////////////////////////////
                            URI
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_tokenExists[tokenId], "URI nonexistent");
        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory newUri) internal {
        _tokenURIs[tokenId] = newUri;

        emit URISet(tokenId, newUri);
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN CREATION
    //////////////////////////////////////////////////////////////*/

    function createToken(uint256 maxSupply_, string calldata uri_, address royaltyReceiver_, uint96 royaltyBps_)
        external
        onlyRole(CREATOR_ROLE)
        returns (uint256 tokenId)
    {
        require(maxSupply_ > 0, "Max supply zero");
        require(bytes(uri_).length > 0, "Empty URI");
        require(royaltyBps_ <= MAX_ROYALTY_BPS, "Royalty too high");

        tokenId = _nextTokenId++;
        _tokenExists[tokenId] = true;
        maxSupply[tokenId] = maxSupply_;

        _setTokenURI(tokenId, uri_);
        creatorOf[tokenId] = msg.sender;

        if (royaltyReceiver_ != address(0) && royaltyBps_ > 0) {
            _setTokenRoyalty(tokenId, royaltyReceiver_, royaltyBps_);
            emit RoyaltySet(tokenId, royaltyReceiver_, royaltyBps_);
        }

        emit TokenCreated(tokenId, maxSupply_, uri_, royaltyReceiver_, royaltyBps_);
        emit CreatorSet(tokenId, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        OPERATOR MINT
    //////////////////////////////////////////////////////////////*/

    event Minted(address indexed to, uint256 indexed tokenId, uint256 amount);

    function mint(address to, uint256 tokenId, uint256 amount) external onlyOperator whenNotPaused whenGlobalNotPaused {
        require(to != address(0), "Mint zero");
        require(_tokenExists[tokenId], "Token missing");
        require(amount > 0, "Bad amount");

        _checkSupply(tokenId, amount);
        _mint(to, tokenId, amount, "");

        emit Minted(to, tokenId, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        LAUNCHPAD MINT
    //////////////////////////////////////////////////////////////*/

    function mintLaunchpad(address to, uint256 tokenId, uint256 amount, string calldata uri_, address creator)
        external
        onlyLaunchpad
        whenNotPaused
        whenGlobalNotPaused
        nonReentrant
    {
        require(to != address(0), "Zero");
        require(amount > 0, "Bad amount");

        // ✅ First-time token creation
        if (!_tokenExists[tokenId]) {
            require(bytes(uri_).length > 0, "Empty URI"); // 🔥 IMPORTANT
            _tokenExists[tokenId] = true;
            maxSupply[tokenId] = type(uint256).max;
            _setTokenURI(tokenId, uri_);

            emit TokenCreated(tokenId, maxSupply[tokenId], uri_, address(0), 0);
        }

        _checkSupply(tokenId, amount);
        _mint(to, tokenId, amount, "");

        emit Minted(to, tokenId, amount);
    }
    /*//////////////////////////////////////////////////////////////
                        LAZY MINT
    //////////////////////////////////////////////////////////////*/

    struct LazyMintVoucher {
        uint256 tokenId;
        uint256 supply;
        uint256 price;
        string uri;
        address creator;
        uint256 nonce;
        uint256 deadline;
        uint256 version;
    }

    bytes32 internal constant LAZY_MINT_TYPEHASH = keccak256(
        "LazyMintVoucher(uint256 tokenId,uint256 supply,uint256 price,string uri,address creator,uint256 nonce,uint256 deadline,uint256 version)"
    );

    function _hashVoucher(LazyMintVoucher calldata v) internal view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    LAZY_MINT_TYPEHASH,
                    v.tokenId,
                    v.supply,
                    v.price,
                    keccak256(bytes(v.uri)),
                    v.creator,
                    v.nonce,
                    v.deadline,
                    v.version
                )
            )
        );
    }

    function lazyMint(LazyMintVoucher calldata voucher, bytes calldata signature, uint256 amount, address to)
        external
        onlyMarketplace
        nonReentrant
        whenNotPaused
        whenGlobalNotPaused
    {
        require(block.timestamp <= voucher.deadline, "Expired");
        require(voucher.version == 1, "Bad version");
        require(amount > 0, "Bad amount");
        require(voucher.nonce == nonces[voucher.creator], "Bad nonce");
        require(bytes(voucher.uri).length > 0, "Empty URI");

        bytes32 digest = _hashVoucher(voucher);
        require(!usedVouchers[digest], "Used");

        address signer = ECDSA.recover(digest, signature);
        require(signer == voucher.creator, "Bad sig");
        require(hasRole(CREATOR_ROLE, signer), "Not creator");

        uint256 newSupply = totalSupply(voucher.tokenId) + amount;
        require(newSupply <= voucher.supply && newSupply <= maxSupply[voucher.tokenId], "Supply exceeded");

        usedVouchers[digest] = true;
        nonces[voucher.creator]++;

        if (!_tokenExists[voucher.tokenId]) {
            _tokenExists[voucher.tokenId] = true;
            maxSupply[voucher.tokenId] = voucher.supply;
            _setTokenURI(voucher.tokenId, voucher.uri);
        }

        _mint(to, voucher.tokenId, amount, "");
        creatorOf[voucher.tokenId] = voucher.creator;

        emit Minted(to, voucher.tokenId, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _checkSupply(uint256 id, uint256 amount) internal view {
        require(totalSupply(id) + amount <= maxSupply[id], "Max supply");
    }

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._update(from, to, ids, values);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, ERC2981Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
