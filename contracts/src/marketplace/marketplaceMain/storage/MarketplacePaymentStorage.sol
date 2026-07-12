// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MarketplacePaymentStorage
/// @author Nexvel
/// @notice Storage for payment-related state.
/// @dev
/// This contract stores only payment state.
///
/// Responsibilities:
/// - Pending Refunds
/// - Future Escrow State
/// - Future Payment Nonces
///
/// IMPORTANT:
/// Never reorder existing variables.
/// Always append new variables before the storage gap.
abstract contract MarketplacePaymentStorage {

    /*//////////////////////////////////////////////////////////////
                            REFUNDS
    //////////////////////////////////////////////////////////////*/

    /// @notice Pending refunds for outbid auction participants.
    mapping(address => uint256)
        internal _pendingRefunds;

    /*//////////////////////////////////////////////////////////////
                            STORAGE GAP
    //////////////////////////////////////////////////////////////*/

    uint256[50] private __gap;
}