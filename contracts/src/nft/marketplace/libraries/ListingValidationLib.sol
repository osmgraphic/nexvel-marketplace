// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";
import {MarketplaceErrors} from "../errors/MarketplaceErrors.sol";
import {ValidationLib} from "./ValidationLib.sol";

/// @title ListingValidationLib
/// @author Nexvel
/// @notice Validation library for marketplace listings.
/// @dev
/// This library contains all business validation related to
/// listing lifecycle and purchase validation.
///
/// Responsibilities:
/// - Listing creation
/// - Listing updates
/// - Listing cancellation
/// - Listing purchase
///
/// This library never:
/// - Reads contract storage
/// - Transfers assets
/// - Emits events
/// - Makes external calls
library ListingValidationLib {
    using ValidationLib for uint256;
    using ValidationLib for address;

    /*//////////////////////////////////////////////////////////////
                        CREATE LISTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates listing creation.
    /// @param params Listing creation parameters.
    function validateCreateListing(MarketplaceTypes.CreateListingParams memory params) internal view {
        ValidationLib.validateAddress(params.nft);

        ValidationLib.validatePrice(params.pricePerUnit);

        ValidationLib.validateQuantity(params.quantity);

        ValidationLib.validateExpiry(params.expiry);
    }

    /*//////////////////////////////////////////////////////////////
                        UPDATE LISTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates listing update.
    /// @param listing Existing listing.
    /// @param params Update parameters.
    /// @param sender Transaction sender.
    function validateUpdateListing(
        MarketplaceTypes.Listing memory listing,
        MarketplaceTypes.UpdateListingParams memory params,
        address sender
    ) internal view {
        if (listing.seller == address(0)) {
            revert MarketplaceErrors.ListingNotFound(listing.id);
        }

        if (listing.seller != sender) {
            revert MarketplaceErrors.NotListingOwner();
        }

        ValidationLib.validatePrice(params.newPrice);

        ValidationLib.validateExpiry(params.newExpiry);
    }

    /*//////////////////////////////////////////////////////////////
                        CANCEL LISTING
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates listing cancellation.
    /// @param listing Listing.
    /// @param sender Transaction sender.
    function validateCancelListing(MarketplaceTypes.Listing memory listing, address sender) internal pure {
        if (listing.seller == address(0)) {
            revert MarketplaceErrors.ListingNotFound(listing.id);
        }

        if (listing.seller != sender) {
            revert MarketplaceErrors.NotListingOwner();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        PURCHASE
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates listing purchase.
    /// @param listing Listing.
    /// @param quantity Purchase quantity.
    /// @param expectedPrice Expected unit price.
    /// @param buyer Buyer.
    function validatePurchase(
        MarketplaceTypes.Listing memory listing,
        uint256 quantity,
        uint256 expectedPrice,
        address buyer
    ) internal view {
        if (listing.seller == address(0)) {
            revert MarketplaceErrors.ListingNotFound(listing.id);
        }

        if (buyer == listing.seller) {
            revert MarketplaceErrors.CannotBuyOwnListing();
        }

        ValidationLib.validateExpiry(listing.expiry);

        ValidationLib.validateExpectedPrice(expectedPrice, listing.pricePerUnit);

        ValidationLib.validateAvailableQuantity(quantity, listing.quantity);

        if (listing.assetType == MarketplaceTypes.AssetType.ERC721) {
            ValidationLib.validateERC721Quantity(quantity);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        STATUS
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates listing is active.
    /// @param listing Listing.
    function validateActiveListing(MarketplaceTypes.Listing memory listing) internal view {
        if (listing.seller == address(0)) {
            revert MarketplaceErrors.ListingNotFound(listing.id);
        }

        ValidationLib.validateExpiry(listing.expiry);

        ValidationLib.validateQuantity(listing.quantity);
    }
}
