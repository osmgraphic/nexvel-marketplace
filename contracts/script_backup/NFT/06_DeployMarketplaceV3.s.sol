// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

/*//////////////////////////////////////////////////////////////
                        MARKETPLACE
//////////////////////////////////////////////////////////////*/
import {NexvelMarketplace} from "../../src/marketplace/NexvelMarketplace.sol";

import {NexvelMarketplaceV3} from "../../src/marketplace/NexvelMarketplaceV3.sol";

contract DeployMarketplaceV3 is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address marketplaceProxy = vm.envAddress("MARKETPLACE_PROXY");

        vm.startBroadcast(deployerKey);

        /*//////////////////////////////////////////////////////////////
                            NEW IMPLEMENTATION
        //////////////////////////////////////////////////////////////*/
        NexvelMarketplaceV3 implV3 = new NexvelMarketplaceV3();

        /*//////////////////////////////////////////////////////////////
                            UUPS UPGRADE
            ⚠️ Caller MUST have ADMIN_ROLE
        //////////////////////////////////////////////////////////////*/
        NexvelMarketplace(payable(marketplaceProxy))
            .upgradeToAndCall(address(implV3), abi.encodeWithSelector(NexvelMarketplaceV3.initializeV3.selector));

        vm.stopBroadcast();

        /*//////////////////////////////////////////////////////////////
                            LOGS
        //////////////////////////////////////////////////////////////*/
        console2.log("=== MARKETPLACE UPGRADED TO V3 (UUPS) ===");
        console2.log("Marketplace Proxy :", marketplaceProxy);
        console2.log("Marketplace Impl V3 :", address(implV3));
    }
}
