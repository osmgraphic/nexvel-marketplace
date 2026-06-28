// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {NexvelNFTFactory} 
    from "../../src/marketplace/NexvelNFTFactory.sol";

import {MarketplaceAddressRegistry} 
    from "../../src/marketplace/registry/MarketplaceAddressRegistry.sol";

contract DeployNFTFactory is Script {

    function run() external returns (address factory) {

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address admin        = vm.envAddress("ADMIN_ADDRESS");
        address registryAddr = vm.envAddress("REGISTRY_ADDRESS");
        address erc721Impl   = vm.envAddress("ERC721_IMPL");
        address erc721AImpl  = vm.envAddress("ERC721A_IMPL");

        require(admin != address(0), "Admin zero");
        require(registryAddr.code.length > 0, "Registry not contract");
        require(erc721Impl.code.length > 0, "ERC721 impl not contract");
        require(erc721AImpl.code.length > 0, "ERC721A impl not contract");

        MarketplaceAddressRegistry registry =
            MarketplaceAddressRegistry(registryAddr);

        vm.startBroadcast(deployerKey);

        /*//////////////////////////////////////////////////////////////
                            DEPLOY FACTORY
        //////////////////////////////////////////////////////////////*/
        NexvelNFTFactory nftFactory =
            new NexvelNFTFactory(
                admin,
                registryAddr,
                erc721Impl,
                erc721AImpl
            );

        factory = address(nftFactory);

        /*//////////////////////////////////////////////////////////////
                            REGISTRY WIRING
        //////////////////////////////////////////////////////////////*/
        registry.setNFTFactory(factory);

        vm.stopBroadcast();

        console2.log("=== NFT FACTORY DEPLOYED ===");
        console2.log("NFT Factory  :", factory);
        console2.log("Admin        :", admin);
        console2.log("Registry     :", registryAddr);
        console2.log("ERC721 Impl  :", erc721Impl);
        console2.log("ERC721A Impl :", erc721AImpl);
    }
}
