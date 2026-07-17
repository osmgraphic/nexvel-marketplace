// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

// OpenZeppelin Upgrades (Foundry Plugin)
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

// Your staking contract
import {StakingPool} from "../src/defi/StakingPool.sol";

contract DeployStakingPoolScript is Script {
    // Load this from .env
    address nxvToken;

    function setUp() public {
        nxvToken = vm.envAddress("NEXVEL_TOKEN_ADDRESS");
    }

    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        //------------------------------------------------------------
        // 1. Deploy Transparent Proxy for StakingPoolV2
        //------------------------------------------------------------
        address proxy = Upgrades.deployUUPSProxy(
            "StakingPool.sol",
            abi.encodeCall(
                StakingPool.initialize,
                (nxvToken) // initializer input
            )
        );

        //------------------------------------------------------------
        // 2. Log Deployed Addresses
        //------------------------------------------------------------
        console.log("----------------------------------------");
        console.log("StakingPool Transparent Proxy Deployed");
        console.log("Proxy Address:      ", proxy);

        address implementation = Upgrades.getImplementationAddress(proxy);
        console.log("Implementation:     ", implementation);

        address admin = Upgrades.getAdminAddress(proxy);
        console.log("Proxy Admin:        ", admin);
        console.log("----------------------------------------");

        vm.stopBroadcast();
    }
}
