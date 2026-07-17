// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {NexvelERC721} from "./NexvelERC721.sol";

/**
 * @title NexvelERC721Impl
 * @notice Concrete deployable implementation of NexvelERC721
 * @dev Exists ONLY to allow factory deployment.
 *      Contains no additional logic.
 */
contract NexvelERC721Impl is NexvelERC721 {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
}
