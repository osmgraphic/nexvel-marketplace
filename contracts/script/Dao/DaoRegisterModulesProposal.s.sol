// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

interface IGovernor {
    function propose(address[] memory, uint256[] memory, bytes[] memory, string memory) external returns (uint256);
}

contract DaoRegisterModulesProposal is Script {
    bytes32 constant MARKETING = keccak256("MARKETING");
    bytes32 constant OPS = keccak256("OPERATIONS");
    bytes32 constant LP = keccak256("LIQUIDITY");
    bytes32 constant AIRDROPS = keccak256("AIRDROPS");

    function run() external {
        address governor = vm.envAddress("GOVERNOR_ADDRESS");
        address treasury = vm.envAddress("TREASURY_PROXY");

        vm.startBroadcast();

        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory calls = new bytes[](4);

        targets[0] = treasury;
        calls[0] = abi.encodeWithSignature("registerModule(bytes32,uint256)", MARKETING, 50_000 ether);

        targets[1] = treasury;
        calls[1] = abi.encodeWithSignature("registerModule(bytes32,uint256)", OPS, 50_000 ether);

        targets[2] = treasury;
        calls[2] = abi.encodeWithSignature("registerModule(bytes32,uint256)", LP, 50_000 ether);

        targets[3] = treasury;
        calls[3] = abi.encodeWithSignature("registerModule(bytes32,uint256)", AIRDROPS, 50_000 ether);

        uint256 proposalId = IGovernor(governor).propose(targets, values, calls, "DAO: Register Treasury Modules");

        console2.log("Proposal ID:", proposalId);

        vm.stopBroadcast();
    }
}
