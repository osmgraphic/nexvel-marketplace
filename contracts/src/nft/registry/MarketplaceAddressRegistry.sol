// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MarketplaceAddressRegistry
 * @notice Canonical address registry for the Nexvel Marketplace protocol.
 *
 * This registry acts as the single source of truth for all protocol
 * contract addresses. Backend services, indexers, frontends and
 * off-chain infrastructure should always resolve addresses from this
 * contract instead of hardcoding them.
 *
 * GOVERNANCE MODEL
 * ----------------
 * - Controlled by Registry Owner
 * - Registry Owner is independent from Marketplace Admin
 * - Supports future protocol upgrades without backend redeployment
 */
contract MarketplaceAddressRegistry is Ownable {
    /*//////////////////////////////////////////////////////////////
                            PROTOCOL INFO
    //////////////////////////////////////////////////////////////*/

    uint256 public constant VERSION = 1;

    string public constant PROTOCOL_NAME = "Nexvel Marketplace";

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

    /// @dev Alias for Ownable OwnershipTransferred event
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
                        REGISTRY OWNER
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

    function setNftFactory(address addr) external onlyRegistryOwner {
        require(addr != address(0), "Zero address");
        require(addr.code.length > 0, "Not contract");
        require(addr != nftFactory, "Already set");

        emit NFTFactoryUpdated(nftFactory, addr);

        nftFactory = addr;
    }

    /*//////////////////////////////////////////////////////////////
                        OWNERSHIP
    //////////////////////////////////////////////////////////////*/

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

    function version() external pure returns (uint256) {
        return VERSION;
    }

    function protocolName() external pure returns (string memory) {
        return PROTOCOL_NAME;
    }

    function chainId() external view returns (uint256) {
        return block.chainid;
    }

    function isInitialized() public view returns (bool) {
        return security != address(0) && marketplace != address(0) && launchpad != address(0) && erc1155 != address(0)
            && nftFactory != address(0);
    }

    function metadata()
        external
        view
        returns (string memory protocol, uint256 version_, uint256 chainId_, bool initialized)
    {
        return (PROTOCOL_NAME, VERSION, block.chainid, isInitialized());
    }
}
