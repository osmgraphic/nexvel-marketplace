// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

interface IGovernor {
    function execute(address[] memory, uint256[] memory, bytes[] memory, bytes32) external payable;
}

contract DaoExecuteProposal is Script {
    function run() external {
        address governor = vm.envAddress("GOVERNOR_ADDRESS");

        bytes32 descHash = keccak256(bytes("DAO: Register Treasury Modules"));

        vm.startBroadcast();

        IGovernor(governor).execute(new address[](0), new uint256[](0), new bytes[](0), descHash);

        vm.stopBroadcast();
    }
}
