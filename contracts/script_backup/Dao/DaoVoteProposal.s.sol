// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";

interface IGovernor {
    function castVote(uint256 proposalId, uint8 support) external;
}

contract DaoVoteProposal is Script {
    function run() external {
        address governor = vm.envAddress("GOVERNOR_ADDRESS");
        uint256 proposalId = vm.envUint("PROPOSAL_ID");

        vm.startBroadcast();

        // 0 = Against, 1 = For, 2 = Abstain
        IGovernor(governor).castVote(proposalId, 1);

        vm.stopBroadcast();
    }
}
