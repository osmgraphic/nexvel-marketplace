// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {NexvelSecurityUpgradeable} from "./NexvelSecurityUpgradeable.sol";

contract NexvelSecurityImpl is NexvelSecurityUpgradeable {
    function initialize(address admin_, address operator_, address registry_, address[] calldata creators_)
        external
        initializer
    {
        __NexvelSecurity_init(admin_, operator_, registry_, creators_);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
}
