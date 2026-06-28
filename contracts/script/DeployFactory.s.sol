// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//------------------------------------------------------
// 🔹 Import Foundry & OpenZeppelin Upgrade Tools
//------------------------------------------------------
import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {Options} from "openzeppelin-foundry-upgrades/Options.sol";

//------------------------------------------------------
// 🔹 Import Contracts
//------------------------------------------------------

import {TokenFactory} from "../src/factory/TokenFactory.sol";

contract DeployFactoryScript is Script {
    //--------------------------------------------------
    // Environment / Parameters
    //--------------------------------------------------
    address public admin;
    address public feeReceiver_;
    uint256 public deployerPrivateKey;

    //--------------------------------------------------
    // Load ENV before run
    //--------------------------------------------------
    function setUp() public {
        admin = vm.envAddress("ADMIN");
        feeReceiver_ = vm.envAddress("FEE_RECEIVER");
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    }

    //--------------------------------------------------
    // 🔹 Deploy Script Entry
    //--------------------------------------------------
    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        console2.log(" Starting deployment of NexvelToken + TokenFactory...");

        //--------------------------------------------------
        // 1️⃣ Deploy NexvelToken Implementation
        //--------------------------------------------------
        Options memory implOpts;
        implOpts.unsafeSkipAllChecks = true;

        address nexvelImpl = Upgrades.deployImplementation("NexvelToken", implOpts);
        console2.log(" NexvelToken Implementation deployed at:", nexvelImpl);

        //--------------------------------------------------
        // 2️⃣ Prepare Factory Initialization Data
        //--------------------------------------------------
        bytes memory initData = abi.encodeCall(TokenFactory.initialize, (nexvelImpl));

        //--------------------------------------------------
        // 3️⃣ Deploy TokenFactory as UUPS Proxy
        //--------------------------------------------------
        Options memory proxyOpts;
        proxyOpts.unsafeSkipAllChecks = true;

        address proxy = Upgrades.deployUUPSProxy("TokenFactory.sol", initData, proxyOpts);
        console2.log(" TokenFactory Proxy deployed at:", proxy);

        //--------------------------------------------------
        // 4️⃣ Fetch Implementation Address
        //--------------------------------------------------
        address factoryImpl = Upgrades.getImplementationAddress(proxy);
        console2.log(" TokenFactory Implementation deployed at:", factoryImpl);

        //--------------------------------------------------
        // Summary
        //--------------------------------------------------
        console2.log("\n Deployment Summary:");
        console2.log("---------------------------");
        console2.log("NexvelToken Implementation:", nexvelImpl);
        console2.log("TokenFactory Proxy:", proxy);
        console2.log("TokenFactory Implementation:", factoryImpl);
        console2.log("---------------------------");

        vm.stopBroadcast();
    }
}
