// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC721AUpgradeable} from "lib/erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {NexvelSecurityUpgradeable} from "./security/NexvelSecurityUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title NexvelERC721A
 * @notice Gas-optimized ERC721A NFT for Nexvel Launchpad
 */
contract NexvelERC721A is Initializable, ERC721AUpgradeable, IERC2981, NexvelSecurityUpgradeable {
    /*//////////////////////////////////////////////////////////////
                              CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint96 public constant MAX_ROYALTY_BPS = 1000;
    uint256 private constant BPS = 10_000;

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public maxSupply;
    string private baseTokenURI;

    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyBps;
    }

    mapping(uint256 => RoyaltyInfo) private _royalties;
    mapping(uint256 => address) public creatorOf;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event BaseURIUpdated(string newBaseURI);
    event BatchMinted(
        address indexed to,
        uint256 startTokenId,
        uint256 quantity,
        address royaltyReceiver,
        uint96 royaltyBps,
        address indexed creator
    );

    event RoyaltySet(uint256 indexed tokenId, address indexed receiver, uint96 royaltyBps);

    event MetadataUpdated(string newBaseURI);

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

        __ERC721A_init(name_, symbol_);
        __NexvelSecurity_init(admin_, operator_, registry_, creators_);

        maxSupply = maxSupply_;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN
    //////////////////////////////////////////////////////////////*/

    function setBaseURI(string calldata uri) external onlyAdmin {
        require(bytes(uri).length > 0, "Empty URI");

        baseTokenURI = uri;

        emit BaseURIUpdated(uri);
        emit MetadataUpdated(uri);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                        LAUNCHPAD MINT
    //////////////////////////////////////////////////////////////*/

    function mintBatchLaunchpad(address to, uint256 quantity, address royaltyReceiver, uint96 royaltyBps)
        external
        onlyLaunchpad
        nonReentrant
    {
        require(bytes(baseTokenURI).length > 0, "Base URI not set");
        require(quantity > 0, "Zero quantity");
        require(royaltyBps <= MAX_ROYALTY_BPS, "Royalty too high");
        require(maxSupply > 0, "Invalid supply");

        _checkSupply(quantity);

        uint256 startTokenId = _nextTokenId();
        _mint(to, quantity);

        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = startTokenId + i;

            creatorOf[tokenId] = msg.sender;

            if (royaltyReceiver != address(0) && royaltyBps > 0) {
                _royalties[tokenId] = RoyaltyInfo({receiver: royaltyReceiver, royaltyBps: royaltyBps});

                emit RoyaltySet(tokenId, royaltyReceiver, royaltyBps);
            }
        }

        emit BatchMinted(to, startTokenId, quantity, royaltyReceiver, royaltyBps, msg.sender);
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

    function _checkSupply(uint256 quantity) internal view {
        if (maxSupply > 0) {
            require(_nextTokenId() + quantity - 1 <= maxSupply, "Max supply reached");
        }
    }

    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
        delete _royalties[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
