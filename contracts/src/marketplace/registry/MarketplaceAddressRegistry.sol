// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MarketplaceAddressRegistry
 * @notice Canonical address registry for Nexvel protocol
 *
 * GOVERNANCE MODEL:
 * - Controlled by a Registry Owner
 * - Registry Owner ≠ Marketplace admin
 */
contract MarketplaceAddressRegistry is Ownable {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public security;
    address public marketplace;
    address public launchpad;
    address public erc1155;
    address public nftFactory;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Alias for Ownable.OwnershipTransferred
    event RegistryOwnershipTransferred(address indexed previousRegistryOwner, address indexed newRegistryOwner);
    event SecurityUpdated(address indexed oldAddr, address indexed newAddr);
    event MarketplaceUpdated(address indexed oldAddr, address indexed newAddr);
    event LaunchpadUpdated(address indexed oldAddr, address indexed newAddr);
    event ERC1155Updated(address indexed oldAddr, address indexed newAddr);
    event NFTFactoryUpdated(address indexed oldAddr, address indexed newAddr);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyRegistryOwner() {
        _checkOwner();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address registryOwner_) Ownable(registryOwner_) {
        require(registryOwner_ != address(0), "Registry owner zero");
    }

    /*//////////////////////////////////////////////////////////////
                        REGISTRY OWNER VIEW
    //////////////////////////////////////////////////////////////*/

    function registryOwner() external view returns (address) {
        return owner();
    }

    /*//////////////////////////////////////////////////////////////
                        REGISTRY SETTERS
    //////////////////////////////////////////////////////////////*/

    function setSecurity(address addr) external onlyRegistryOwner {
        require(addr != address(0), "Zero address");
        require(addr.code.length > 0, "Not contract");
        require(addr != security, "Already set");
        emit SecurityUpdated(security, addr);
        security = addr;
    }

    function setMarketplace(address addr) external onlyRegistryOwner {
        require(addr != address(0), "Zero address");
        require(addr.code.length > 0, "Not contract");
        require(addr != marketplace, "Already set");
        emit MarketplaceUpdated(marketplace, addr);
        marketplace = addr;
    }

    function setLaunchpad(address addr) external onlyRegistryOwner {
        require(addr != address(0), "Zero address");
        require(addr.code.length > 0, "Not contract");
        require(addr != launchpad, "Already set");
        emit LaunchpadUpdated(launchpad, addr);
        launchpad = addr;
    }

    function setERC1155(address addr) external onlyRegistryOwner {
        require(addr != address(0), "Zero address");
        require(addr.code.length > 0, "Not contract");
        require(addr != erc1155, "Already set");
        emit ERC1155Updated(erc1155, addr);
        erc1155 = addr;
    }

    function setNFTFactory(address addr) external onlyRegistryOwner {
        require(addr != address(0), "Zero address");
        require(addr.code.length > 0, "Not contract");
        require(addr != nftFactory, "Already set");
        emit NFTFactoryUpdated(nftFactory, addr);
        nftFactory = addr;
    }

    /*//////////////////////////////////////////////////////////////
                        OWNERSHIP OVERRIDE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emit RegistryOwnershipTransferred alongside Ownable event.
     */
    function _transferOwnership(address newOwner) internal override {
        address previousOwner = owner();
        super._transferOwnership(newOwner);

        emit RegistryOwnershipTransferred(previousOwner, newOwner);
    }

    /*//////////////////////////////////////////////////////////////
                            READ HELPERS
    //////////////////////////////////////////////////////////////*/

    function allAddresses()
        external
        view
        returns (address security_, address marketplace_, address launchpad_, address erc1155_, address nftFactory_)
    {
        return (security, marketplace, launchpad, erc1155, nftFactory);
    }
}
