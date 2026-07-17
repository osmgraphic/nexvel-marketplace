// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IMarketplaceRegistry} from "../interfaces/IMarketplaceRegistry.sol";

/// @title MarketplaceConfigStorage
/// @author Nexvel
/// @notice Shared storage used by all marketplace modules.
/// @dev
/// This contract stores only shared configuration.
/// It MUST NOT contain business logic.
///
/// IMPORTANT:
/// - Never reorder existing variables.
/// - Only append new variables before the storage gap.
abstract contract MarketplaceConfigStorage {
    /*//////////////////////////////////////////////////////////////
                            REGISTRY
    //////////////////////////////////////////////////////////////*/

    /// @notice Marketplace registry contract.
    IMarketplaceRegistry internal _registry;

    /*//////////////////////////////////////////////////////////////
                            STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    uint256[49] private _gap;
}
