// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

/*//////////////////////////////////////////////////////////////
                        MARKETPLACE
//////////////////////////////////////////////////////////////*/
import {NexvelMarketplace} from "../../src/marketplace/NexvelMarketplace.sol";

import {NexvelMarketplaceV2} from "../../src/marketplace/NexvelMarketplaceV2.sol";

contract DeployMarketplaceV2 is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address marketplaceProxy = vm.envAddress("MARKETPLACE_PROXY_V1");

        vm.startBroadcast(deployerKey);

        /*//////////////////////////////////////////////////////////////
                            NEW IMPLEMENTATION
        //////////////////////////////////////////////////////////////*/
        NexvelMarketplaceV2 implV2 = new NexvelMarketplaceV2();

        /*//////////////////////////////////////////////////////////////
                            UUPS UPGRADE
            ⚠️ Caller MUST have ADMIN_ROLE
        //////////////////////////////////////////////////////////////*/
        NexvelMarketplace(payable(marketplaceProxy))
            .upgradeToAndCall(address(implV2), abi.encodeWithSelector(NexvelMarketplaceV2.initializeV2.selector));

        vm.stopBroadcast();

        /*//////////////////////////////////////////////////////////////
                            LOGS
        //////////////////////////////////////////////////////////////*/
        console2.log("=== MARKETPLACE UPGRADED TO V2 (UUPS) ===");
        console2.log("Marketplace Proxy :", marketplaceProxy);
        console2.log("Marketplace Impl V2 :", address(implV2));
    }
}
