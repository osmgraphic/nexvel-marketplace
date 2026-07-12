// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";
import {MarketplaceErrors} from "../errors/MarketplaceErrors.sol";

/// @title RoyaltyLib
/// @author Nexvel
/// @notice Stateless ERC2981 royalty calculation library.
/// @dev
/// This library:
/// - Never stores state
/// - Never transfers funds
/// - Never emits events
/// - Never performs marketplace logic
///
/// It only calculates royalty information.
///
/// Supports:
/// - ERC2981
/// - Non-royalty NFTs (returns zero royalty)
library RoyaltyLib {
    bytes4 internal constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    /*//////////////////////////////////////////////////////////////
                            ROYALTY
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculates royalty information for an NFT sale.
    /// @param nft NFT contract.
    /// @param tokenId Token identifier.
    /// @param salePrice Sale price.
    /// @return receiver Royalty receiver.
    /// @return royaltyAmount Royalty amount.
    function calculateRoyalty(
        address nft,
        uint256 tokenId,
        uint256 salePrice
    )
        internal
        view
        returns (
            address receiver,
            uint256 royaltyAmount
        )
    {
        if (
            nft == address(0) ||
            salePrice == 0
        ) {
            return (address(0), 0);
        }

        if (!supportsERC2981(nft)) {
            return (address(0), 0);
        }

        (receiver, royaltyAmount) =
            IERC2981(nft).royaltyInfo(
                tokenId,
                salePrice
            );

        if (
            receiver == address(0) ||
            royaltyAmount == 0
        ) {
            return (address(0), 0);
        }

        if (royaltyAmount > salePrice) {
            revert MarketplaceErrors.InvalidRoyalty();
        }
    }


    /*//////////////////////////////////////////////////////////////
                        ERC2981
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether an NFT supports ERC2981.
    /// @param nft NFT contract.
    /// @return supported True if ERC2981 is supported.
    function supportsERC2981(
        address nft
    )
        internal
        view
        returns (bool supported)
    {
        if (nft == address(0)) {
            return false;
        }

        try IERC165(nft).supportsInterface(
            _INTERFACE_ID_ERC2981
        ) returns (bool ok) {
            supported = ok;
        } catch {
            supported = false;
        }
    }

    /*//////////////////////////////////////////////////////////////
                        HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns true if royalty exists.
    /// @param royaltyAmount Royalty amount.
    function hasRoyalty(
        uint256 royaltyAmount
    )
        internal
        pure
        returns (bool)
    {
        return royaltyAmount != 0;
    }


}