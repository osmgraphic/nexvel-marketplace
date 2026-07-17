// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//------------------------------------------------------
// 🔹 OpenZeppelin v5 Upgradeable Imports
//------------------------------------------------------
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {GovernorUpgradeable} from "@openzeppelin/contracts-upgradeable/governance/GovernorUpgradeable.sol";
import {
    GovernorSettingsUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorSettingsUpgradeable.sol";
import {
    GovernorCountingSimpleUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorCountingSimpleUpgradeable.sol";
import {
    GovernorVotesUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import {
    GovernorVotesQuorumFractionUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorVotesQuorumFractionUpgradeable.sol";
import {
    GovernorTimelockControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/extensions/GovernorTimelockControlUpgradeable.sol";

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {
    TimelockControllerUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

/// @title Nexvel DAO Governor (Upgradeable)
/// @notice Governor + Timelock + Quorum + UUPS upgradeable
contract GovernorNexvel is
    Initializable,
    GovernorUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorVotesUpgradeable,
    GovernorVotesQuorumFractionUpgradeable,
    GovernorTimelockControlUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    //------------------------------------------------------
    // 🔹 Roles
    //------------------------------------------------------
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    //------------------------------------------------------
    // 🔹 Initializer
    //------------------------------------------------------
    function initialize(IVotes _token, TimelockControllerUpgradeable _timelock, uint256 quorumPercent)
        public
        initializer
    {
        __Governor_init("Nexvel Governor");
        __GovernorSettings_init(
            1, // voting delay
            45818, // ~1 week voting period
            100e18 // proposal threshold
        );
        __GovernorCountingSimple_init();
        __GovernorVotes_init(_token);
        __GovernorVotesQuorumFraction_init(quorumPercent);
        __GovernorTimelockControl_init(_timelock);

        __AccessControl_init();

        // Grant UPGRADER_ROLE to the deployer (you may transfer later)
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    //------------------------------------------------------
    // 🔹 UUPS Authorization
    //------------------------------------------------------
    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    //------------------------------------------------------
    // 🔹 Voting Parameters (override required in OZ v5)
    //------------------------------------------------------
    function votingDelay() public pure override(GovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return 1;
    }

    function votingPeriod() public pure override(GovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return 45818; // ~1 week
    }

    function proposalThreshold()
        public
        pure
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return 100e18;
    }

    //------------------------------------------------------
    // 🔹 Required Overrides
    //------------------------------------------------------
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(GovernorUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function state(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function proposalNeedsQueuing(uint256 proposalId)
        public
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (bool)
    {
        return super.proposalNeedsQueuing(proposalId);
    }

    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }
}
