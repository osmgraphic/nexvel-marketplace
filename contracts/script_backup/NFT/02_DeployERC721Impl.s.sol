// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {NexvelERC721Impl} from "../../src/marketplace/NexvelERC721Impl.sol";

contract DeployERC721Impl is Script {
    function run() external returns (address implAddr) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        NexvelERC721Impl impl = new NexvelERC721Impl();
        implAddr = address(impl);

        vm.stopBroadcast();

        console2.log("=== ERC721 IMPLEMENTATION DEPLOYED ===");
        console2.log("ERC721 Impl :", implAddr);
    }
}
