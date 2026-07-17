// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {NexvelTimelockController} from "src/governance/NexvelTimelockController.sol";

import {GovernorNexvel} from "../src/governance/GovernorNexvel.sol";

contract DeployGovernance is Script {
    address public tokenAddress = vm.envAddress("NEXVEL_TOKEN_ADDRESS");
    address public admin = vm.envAddress("ADMIN");
    uint256 public minDelay = 2 days;
    uint256 quorumPercent = 4;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        console2.log("Deploying Governance...");

        // -------------------------------------------
        // 1️⃣ Deploy TimelockController (Transparent Proxy)
        // -------------------------------------------
        address timelockProxyAddress = Upgrades.deployUUPSProxy(
            "NexvelTimelockController.sol",
            abi.encodeCall(NexvelTimelockController.initialize, (minDelay, new address[](0), new address[](0), admin))
        );

        NexvelTimelockController timelock = NexvelTimelockController(payable(timelockProxyAddress));

        console2.log("Timelock deployed at:", timelockProxyAddress);

        // -------------------------------------------
        // 2️⃣ Deploy Governor (UUPS Proxy)
        // -------------------------------------------
        address governorProxyAddress = Upgrades.deployUUPSProxy(
            "GovernorNexvel.sol",
            abi.encodeWithSelector(
                GovernorNexvel.initialize.selector, tokenAddress, timelockProxyAddress, quorumPercent
            )
        );

        console2.log("Governor deployed at:", governorProxyAddress);

        // -------------------------------------------
        // 3️⃣ Assign Roles
        // -------------------------------------------
        timelock.grantRole(timelock.PROPOSER_ROLE(), governorProxyAddress);
        timelock.grantRole(timelock.EXECUTOR_ROLE(), governorProxyAddress);

        timelock.revokeRole(timelock.DEFAULT_ADMIN_ROLE(), admin);

        vm.stopBroadcast();

        console2.log("======== SUMMARY ========");
        console2.log("Governor:", governorProxyAddress);
        console2.log("Timelock:", timelockProxyAddress);
        console2.log("Token:", tokenAddress);
        console2.log("=========================");
    }
}
