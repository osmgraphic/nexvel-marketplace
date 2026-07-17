// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/defi/MerkleAirdrop.sol";

contract DeployAirdrop is Script {
    function run() external {
        address token = vm.envAddress("NEXVEL_TOKEN_ADDRESS"); // Example token address
        bytes32 root = vm.envBytes32("Merkle_Root");

        vm.startBroadcast();
        new MerkleAirdrop(token, root);
        vm.stopBroadcast();
    }
}
