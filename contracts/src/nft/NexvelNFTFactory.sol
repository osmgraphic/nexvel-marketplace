// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*//////////////////////////////////////////////////////////////
                            IMPORTS
//////////////////////////////////////////////////////////////*/

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IMarketplaceAddressRegistry} from "./interfaces/IMarketplaceAddressRegistry.sol";
import {INexvelNFTInitializable} from "./interfaces/INexvelNFTInitializable.sol";
import {NexvelSecurityUpgradeable} from "./security/NexvelSecurityUpgradeable.sol";

/*//////////////////////////////////////////////////////////////
                        CONTRACT
//////////////////////////////////////////////////////////////*/

contract NexvelNFTFactory is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                ENUM
    //////////////////////////////////////////////////////////////*/

    enum NFTType {
        ERC721,
        ERC721A
    }

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public immutable admin;
    IMarketplaceAddressRegistry public registry;

    address public erc721Impl;
    address public erc721AImpl;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when a new NFT collection is created
     *
     * Indexed fields allow easy filtering via `cast logs`
     */
    event CollectionCreated(
        address indexed creator,
        address indexed collection,
        address indexed implementation,
        NFTType nftType,
        string name,
        string symbol,
        uint256 maxSupply
    );

    event RegistryUpdated(address indexed newRegistry);
    event ImplementationsUpdated(address erc721Impl, address erc721AImpl);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyCreator() {
        address securityAddr = registry.security();
        require(securityAddr != address(0), "Security not set");

        require(
            NexvelSecurityUpgradeable(securityAddr)
                .hasRole(NexvelSecurityUpgradeable(securityAddr).CREATOR_ROLE(), msg.sender),
            "Not creator"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address admin_, address registry_, address erc721Impl_, address erc721AImpl_) {
        require(admin_ != address(0), "Admin zero");
        require(registry_ != address(0), "Registry zero");
        require(erc721Impl_ != address(0), "ERC721 impl zero");
        require(erc721AImpl_ != address(0), "ERC721A impl zero");

        admin = admin_;
        registry = IMarketplaceAddressRegistry(registry_);
        erc721Impl = erc721Impl_;
        erc721AImpl = erc721AImpl_;
    }

    /*//////////////////////////////////////////////////////////////
                            NFT CREATION
    //////////////////////////////////////////////////////////////*/

    function createNFT(
        string calldata name_,
        string calldata symbol_,
        NFTType nftType,
        address operator_,
        address[] calldata creators_,
        uint256 maxSupply_
    ) external nonReentrant onlyCreator returns (address collection) {
        address implementation = nftType == NFTType.ERC721 ? erc721Impl : erc721AImpl;

        require(implementation.code.length > 0, "Invalid implementation");
        require(maxSupply_ > 0, "Invalid max supply");
        require(creators_.length > 0, "No creators");
        require(operator_ != address(0), "Invalid operator");
        require(bytes(name_).length <= 64, "Empty name");
        require(bytes(symbol_).length <= 12, "Empty symbol");
        require(erc721Impl != erc721AImpl, "Same implementation");

        collection = Clones.clone(implementation);
        require(collection != address(0), "Clone failed");

        INexvelNFTInitializable(collection)
            .initialize(name_, symbol_, admin, address(registry), operator_, creators_, maxSupply_);

        emit CollectionCreated(msg.sender, collection, implementation, nftType, name_, symbol_, maxSupply_);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function updateRegistry(address newRegistry) external onlyAdmin {
        require(newRegistry != address(0), "Invalid registry");
        registry = IMarketplaceAddressRegistry(newRegistry);
        emit RegistryUpdated(newRegistry);
    }

    function setImplementations(address erc721Impl_, address erc721AImpl_) external onlyAdmin {
        require(erc721Impl_ != address(0), "ERC721 impl zero");
        require(erc721AImpl_ != address(0), "ERC721A impl zero");

        erc721Impl = erc721Impl_;
        erc721AImpl = erc721AImpl_;

        emit ImplementationsUpdated(erc721Impl_, erc721AImpl_);
    }
}
