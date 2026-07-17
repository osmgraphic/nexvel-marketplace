// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {
    ERC721URIStorageUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {INexvelERC721} from "./interfaces/INexvelERC721.sol";

import {NexvelSecurityUpgradeable} from "./security/NexvelSecurityUpgradeable.sol";

/**
 * @title NexvelERC721
 * @notice Upgradeable ERC721 NFT for Nexvel protocol
 */
abstract contract NexvelERC721 is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    EIP712Upgradeable,
    IERC2981,
    NexvelSecurityUpgradeable,
    INexvelERC721
{
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint96 public constant MAX_ROYALTY_BPS = 1000;
    uint256 private constant BPS = 10_000;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public nextTokenId;
    uint256 public maxSupply;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyBps;
    }

    /*//////////////////////////////////////////////////////////////
                              mapping
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 => address) public creatorOf;
    mapping(uint256 => RoyaltyInfo) private _royalties;
    mapping(address => uint256) public nonces;
    mapping(bytes32 => bool) public usedVouchers;

    /*//////////////////////////////////////////////////////////////
                                  events
    //////////////////////////////////////////////////////////////*/
    event Minted(
        address indexed to,
        uint256 indexed tokenId,
        string uri,
        address royaltyReceiver,
        uint96 royaltyBps,
        address indexed creator
    );

    event RoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 royaltyBps);

    event MetadataUpdated(uint256 indexed tokenId, string newURI);

    event LaunchpadMint(address indexed to, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                        LAZY MINT STRUCT
    //////////////////////////////////////////////////////////////*/

    bytes32 private constant LAZY_MINT_TYPEHASH = keccak256(
        "LazyMintVoucher(address creator,address to,string uri,uint256 price,uint256 nonce,uint256 deadline,uint256 version,address contract)"
    );

    function _hashVoucher(LazyMintVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    LAZY_MINT_TYPEHASH,
                    voucher.creator,
                    voucher.to,
                    keccak256(bytes(voucher.uri)),
                    voucher.price,
                    voucher.nonce,
                    voucher.deadline,
                    voucher.version,
                    address(this) // 🔥 CRITICAL FIX
                )
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_,
        address registry_,
        address operator_,
        address[] calldata creators_,
        uint256 maxSupply_
    ) external initializer {
        require(admin_ != address(0), "Admin zero");

        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
        __EIP712_init("NexvelNFT", "1");
        __NexvelSecurity_init(admin_, operator_, registry_, creators_);

        _grantRole(CREATOR_ROLE, admin_);

        nextTokenId = 1;
        maxSupply = maxSupply_;
    }

    /*//////////////////////////////////////////////////////////////
                        DIRECT MINT
    //////////////////////////////////////////////////////////////*/

    function directMint(address to, string calldata uri, address royaltyReceiver, uint96 royaltyBps)
        external
        onlyCreator
        nonReentrant
        returns (uint256 tokenId)
    {
        require(to != address(0), "Zero address");
        require(bytes(uri).length > 0, "Empty URI");
        require(royaltyBps <= MAX_ROYALTY_BPS, "Royalty too high");
        _checkSupply(1);

        tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        creatorOf[tokenId] = msg.sender;

        if (royaltyReceiver != address(0) && royaltyBps > 0) {
            _royalties[tokenId] = RoyaltyInfo({receiver: royaltyReceiver, royaltyBps: royaltyBps});

            emit RoyaltySet(tokenId, royaltyReceiver, royaltyBps);
        }

        emit Minted(to, tokenId, uri, royaltyReceiver, royaltyBps, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                        LAZY MINT
    //////////////////////////////////////////////////////////////*/

    function lazyMintTo(address to, LazyMintVoucher calldata voucher, bytes calldata signature)
        external
        onlyRole(MARKETPLACE_ROLE)
        nonReentrant
        whenNotPaused
        whenGlobalNotPaused
        returns (uint256 tokenId)
    {
        // ─────────────────────────────────────────────
        // Voucher validation
        // ─────────────────────────────────────────────
        require(voucher.version == 1, "Invalid voucher version");
        require(block.timestamp <= voucher.deadline, "Voucher expired");

        if (voucher.to != address(0)) {
            require(voucher.to == to, "Invalid recipient");
        }

        require(voucher.nonce == nonces[voucher.creator], "Invalid voucher nonce");

        require(hasRole(CREATOR_ROLE, voucher.creator), "Signer not creator");

        bytes32 digest = _hashVoucher(voucher);
        require(!usedVouchers[digest], "Voucher used");

        address signer = ECDSA.recover(digest, signature);
        require(signer == voucher.creator, "Bad signature");

        // ─────────────────────────────────────────────
        // Effects
        // ─────────────────────────────────────────────
        usedVouchers[digest] = true;
        nonces[voucher.creator]++;

        _checkSupply(1);

        tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, voucher.uri);

        // Optional royalty (creator default)
        _royalties[tokenId] = RoyaltyInfo({receiver: voucher.creator, royaltyBps: MAX_ROYALTY_BPS});

        creatorOf[tokenId] = voucher.creator;

        emit RoyaltySet(tokenId, voucher.creator, MAX_ROYALTY_BPS);

        emit Minted(to, tokenId, voucher.uri, voucher.creator, MAX_ROYALTY_BPS, voucher.creator);
    }

    /*//////////////////////////////////////////////////////////////
                        BATCH LAUNCHPAD MINT
    //////////////////////////////////////////////////////////////*/

    function mintBatch721Launchpad(
        address to,
        uint256 amount,
        string calldata uri,
        address royaltyReceiver,
        uint96 royaltyBps
    ) external onlyLaunchpad {
        require(royaltyBps <= MAX_ROYALTY_BPS, "Royalty too high");
        require(maxSupply > 0, "Invalid supply");
        _checkSupply(amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = nextTokenId++;

            _safeMint(to, tokenId);

            _setTokenURI(tokenId, uri);

            if (royaltyBps > 0) {
                _royalties[tokenId] = RoyaltyInfo({receiver: royaltyReceiver, royaltyBps: royaltyBps});
            }
        }

        emit LaunchpadMint(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC2981
    //////////////////////////////////////////////////////////////*/

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address, uint256) {
        RoyaltyInfo memory r = _royalties[tokenId];
        if (r.receiver == address(0)) return (address(0), 0);
        return (r.receiver, (salePrice * r.royaltyBps) / BPS);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _checkSupply(uint256 amount) internal view {
        if (maxSupply > 0) {
            require(nextTokenId + amount - 1 <= maxSupply, "Max supply reached");
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mintLaunchpad(address to, string calldata uri) external override onlyLaunchpad {
        require(bytes(uri).length > 0, "Empty URI");
        _checkSupply(1);

        uint256 tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        creatorOf[tokenId] = msg.sender;

        emit Minted(to, tokenId, uri, address(0), 0, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable, AccessControlUpgradeable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
        revert("ETH not accepted");
    }

    function cancelAllVouchers() external onlyCreator {
        nonces[msg.sender]++;
    }
}
