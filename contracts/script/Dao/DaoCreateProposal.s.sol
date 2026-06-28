// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

interface IERC20 {
    function transfer(address, uint256) external returns (bool);
}

interface IGovernor {
    function propose(address[] memory, uint256[] memory, bytes[] memory, string memory) external returns (uint256);
}

contract DaoCreateProposal is Script {
    function run() external {
        address governor = vm.envAddress("GOVERNOR_ADDRESS");
        address nxv = vm.envAddress("NEXVEL_TOKEN_ADDRESS");
        address treasury = vm.envAddress("TREASURY_PROXY");

        vm.startBroadcast();

        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory calls = new bytes[](4);

        targets[0] = nxv;
        calls[0] = abi.encodeWithSignature("transfer(address,uint256)", treasury, 100_000 ether);

        IGovernor(governor).propose(targets, values, calls, "DAO: Transfer NXV to Treasury");

        vm.stopBroadcast();
    }
}
