// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {NexvelToken} from "./NexvelToken.sol";

contract NexvelTokenv2 is NexvelToken {
    function version() external pure override returns (string memory) {
        return "V2";
    }

    function newFeature() external pure returns (string memory) {
        return "New Feature Active";
    }
}
