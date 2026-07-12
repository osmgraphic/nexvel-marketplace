// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";

/// @title IMarketplacePayment
/// @author Nexvel
/// @notice Stateless payment engine interface for the Nexvel Marketplace.
/// @dev Responsible only for payment execution and fee calculation.
/// Does not perform NFT transfers or marketplace business logic.
interface IMarketplacePayment {
    /*//////////////////////////////////////////////////////////////
                            EXECUTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Executes a marketplace sale.
    /// @param request Payment execution request.
    /// @return breakdown Complete payment breakdown.
    function executeSale(
        MarketplaceTypes.PaymentRequest calldata request
    )
        external
        payable
        returns (
            MarketplaceTypes.FeeBreakdown memory breakdown
        );

    /// @notice Executes an auction settlement.
    /// @param request Payment execution request.
    /// @return breakdown Complete payment breakdown.
    function executeAuctionSettlement(
        MarketplaceTypes.PaymentRequest calldata request
    )
        external
        payable
        returns (
            MarketplaceTypes.FeeBreakdown memory breakdown
        );

    /*//////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculates marketplace fees without executing transfers.
    /// @param request Payment request.
    /// @return breakdown Fee breakdown.
    function calculateFees(
        MarketplaceTypes.PaymentRequest calldata request
    )
        external
        view
        returns (
            MarketplaceTypes.FeeBreakdown memory breakdown
        );
}