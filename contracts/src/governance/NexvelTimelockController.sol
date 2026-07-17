// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
  NexvelTimelockController (wrapper)
  - Wraps OZ TimelockControllerUpgradeable which has internal init in OZ v5
  - Exposes public initializer for proxy deployment
  - Adds UUPS upgrader role
*/

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    TimelockControllerUpgradeable
} from "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NexvelTimelockController is Initializable, TimelockControllerUpgradeable, UUPSUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @notice public initializer wrapper (calls OZ internal init)
    function initialize(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin)
        public
        override
        initializer
    {
        // Call OZ internal initializer
        __TimelockController_init(minDelay, proposers, executors, admin);

        // Init access control & UUPS
        __AccessControl_init();

        // grant upgrader to admin
        _grantRole(UPGRADER_ROLE, admin);
        // keep default admin role granted by Timelock init (admin param)
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
