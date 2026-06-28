// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {NexvelERC721A} from "../../src/marketplace/NexvelERC721A.sol";

contract DeployERC721AImpl is Script {
    function run() external returns (address implAddr) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        NexvelERC721A impl = new NexvelERC721A();
        implAddr = address(impl);

        vm.stopBroadcast();

        console2.log("=== ERC721A IMPLEMENTATION DEPLOYED ===");
        console2.log("ERC721A Impl :", implAddr);
    }
}
