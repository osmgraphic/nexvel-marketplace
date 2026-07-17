// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {MarketplaceAddressRegistry} from "../../src/marketplace/registry/MarketplaceAddressRegistry.sol";

contract DeployAddressRegistry is Script {
    function run() external returns (address registry) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address admin = vm.envAddress("ADMIN_ADDRESS");
        require(admin != address(0), "Admin zero");

        // Optional wiring (can be zero if wiring later)
        address security = vm.envOr("SECURITY_ADDRESS", address(0));
        address marketplace = vm.envOr("MARKETPLACE_ADDRESS", address(0));
        address launchpad = vm.envOr("LAUNCHPAD_ADDRESS", address(0));
        address erc1155 = vm.envOr("ERC1155_ADDRESS", address(0));
        address factory = vm.envOr("NFT_FACTORY_ADDRESS", address(0));

        vm.startBroadcast(deployerKey);

        /*//////////////////////////////////////////////////////////////
                            DEPLOY REGISTRY
        //////////////////////////////////////////////////////////////*/
        MarketplaceAddressRegistry reg = new MarketplaceAddressRegistry(admin);

        /*//////////////////////////////////////////////////////////////
                            OPTIONAL WIRING
        //////////////////////////////////////////////////////////////*/
        if (security != address(0)) {
            reg.setSecurity(security);
        }

        if (marketplace != address(0)) {
            reg.setMarketplace(marketplace);
        }

        if (launchpad != address(0)) {
            reg.setLaunchpad(launchpad);
        }

        if (erc1155 != address(0)) {
            reg.setERC1155(erc1155);
        }

        if (factory != address(0)) {
            reg.setNFTFactory(factory);
        }

        vm.stopBroadcast();

        registry = address(reg);

        /*//////////////////////////////////////////////////////////////
                                LOGS
        //////////////////////////////////////////////////////////////*/
        console2.log("=== NEXVEL REGISTRY DEPLOYED ===");
        console2.log("Registry    :", registry);
        console2.log("Owner       :", admin);
        console2.log("Security    :", security);
        console2.log("Marketplace :", marketplace);
        console2.log("Launchpad   :", launchpad);
        console2.log("ERC1155     :", erc1155);
        console2.log("NFT Factory :", factory);
    }
}
