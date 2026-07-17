// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {MarketplaceConstants} from "../libraries/MarketplaceConstants.sol";
import {MarketplaceErrors} from "../errors/MarketplaceErrors.sol";
import {MarketplaceTypes} from "../types/MarketplaceTypes.sol";

/// @title PaymentLib
/// @author Nexvel
/// @notice Stateless payment helper library for the Nexvel Marketplace.
/// @dev
/// Responsibilities:
/// - Marketplace fee calculation
/// - Seller proceeds calculation
/// - Fee breakdown construction
/// - Safe ETH transfers
/// - Safe ERC20 transfers
/// - Auction refunds
/// - Auction payouts
///
/// This library NEVER:
/// - Reads protocol storage
/// - Reads registry
/// - Transfers NFTs
/// - Emits events
/// - Performs marketplace validation
library PaymentLib {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            FEES
    //////////////////////////////////////////////////////////////*/

    /// @notice Calculates marketplace fee.
    /// @param salePrice Total sale price.
    /// @param feeBps Marketplace fee in basis points.
    /// @return fee Marketplace fee amount.
    function calculateMarketplaceFee(uint256 salePrice, uint96 feeBps) internal pure returns (uint256 fee) {
        uint96 maxFee = MarketplaceConstants.MAX_MARKETPLACE_FEE_BPS;
        if (feeBps > maxFee) {
            revert MarketplaceErrors.MarketplaceFeeTooHigh(feeBps, maxFee);
        }

        fee = (salePrice * feeBps) / MarketplaceConstants.BPS;
    }

    /// @notice Calculates seller proceeds.
    /// @param salePrice Total sale price.
    /// @param marketplaceFee Marketplace fee.
    /// @param royaltyAmount Royalty amount.
    /// @return sellerAmount Amount receivable by seller.
    function calculateSellerAmount(uint256 salePrice, uint256 marketplaceFee, uint256 royaltyAmount)
        internal
        pure
        returns (uint256 sellerAmount)
    {
        if (marketplaceFee + royaltyAmount > salePrice) {
            revert MarketplaceErrors.RoyaltyExceedsSellerAmount();
        }

        sellerAmount = salePrice - marketplaceFee - royaltyAmount;
    }

    /// @notice Builds payment breakdown.
    /// @param salePrice Total sale price.
    /// @param marketplaceFee Marketplace fee.
    /// @param royaltyReceiver Royalty receiver.
    /// @param royaltyAmount Royalty amount.
    /// @return breakdown Fee breakdown.
    function buildFeeBreakdown(
        uint256 salePrice,
        uint256 marketplaceFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    ) internal pure returns (MarketplaceTypes.FeeBreakdown memory breakdown) {
        breakdown.totalPrice = salePrice;

        breakdown.marketplaceFee = marketplaceFee;

        breakdown.royaltyReceiver = royaltyReceiver;
        breakdown.royaltyAmount = royaltyAmount;

        breakdown.sellerAmount = calculateSellerAmount(salePrice, marketplaceFee, royaltyAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        PAYMENT TYPE
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns true if payment token is native ETH.
    /// @param paymentToken Payment token.
    function isNativeToken(address paymentToken) internal pure returns (bool) {
        return paymentToken == MarketplaceConstants.NATIVE_TOKEN;
    }

    /*//////////////////////////////////////////////////////////////
                        ETH TRANSFERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfers native ETH.
    /// @param recipient Recipient.
    /// @param amount Amount.
    function transferEth(address recipient, uint256 amount) internal {
        if (amount == 0) return;

        (bool success,) = payable(recipient).call{value: amount}("");

        if (!success) {
            revert MarketplaceErrors.ETHTransferFailed(recipient, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        ERC20 TRANSFERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfers ERC20 tokens.
    /// @param token ERC20 token.
    /// @param from Sender.
    /// @param to Recipient.
    /// @param amount Amount.
    function transferErc20(address token, address from, address to, uint256 amount) internal {
        if (amount == 0) return;

        IERC20(token).safeTransferFrom(from, to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                    SALE DISTRIBUTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Distributes sale proceeds.
    /// @dev
    /// Distribution order:
    /// 1. Treasury
    /// 2. Royalty receiver
    /// 3. Seller
    ///
    /// @param paymentToken Payment token (address(0) = ETH).
    /// @param payer Buyer / payer.
    /// @param treasury Protocol treasury.
    /// @param seller Seller.
    /// @param breakdown Fee breakdown.
    function distributeSale(
        address paymentToken,
        address payer,
        address treasury,
        address seller,
        MarketplaceTypes.FeeBreakdown memory breakdown
    ) internal {
        if (isNativeToken(paymentToken)) {
            _distributeEth(treasury, seller, breakdown);
        } else {
            _distributeErc20(paymentToken, payer, treasury, seller, breakdown);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        AUCTION PAYOUT
    //////////////////////////////////////////////////////////////*/

    /// @notice Pays auction proceeds.
    /// @param paymentToken Payment token.
    /// @param winner Highest bidder.
    /// @param treasury Treasury.
    /// @param seller Seller.
    /// @param breakdown Fee breakdown.
    function payoutAuction(
        address paymentToken,
        address winner,
        address treasury,
        address seller,
        MarketplaceTypes.FeeBreakdown memory breakdown
    ) internal {
        distributeSale(paymentToken, winner, treasury, seller, breakdown);
    }

    /*//////////////////////////////////////////////////////////////
                        BID REFUND
    //////////////////////////////////////////////////////////////*/

    /// @notice Refunds an outbid bidder.
    /// @param paymentToken Payment token.
    /// @param bidder Bidder to refund.
    /// @param amount Refund amount.
    function refundBid(address paymentToken, address bidder, uint256 amount) internal {
        if (amount == 0) return;

        if (isNativeToken(paymentToken)) {
            transferEth(bidder, amount);
        } else {
            IERC20(paymentToken).safeTransfer(bidder, amount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL ETH PAYOUT
    //////////////////////////////////////////////////////////////*/

    function _distributeEth(address treasury, address seller, MarketplaceTypes.FeeBreakdown memory breakdown) private {
        if (breakdown.marketplaceFee != 0) {
            transferEth(treasury, breakdown.marketplaceFee);
        }

        if (breakdown.royaltyAmount != 0 && breakdown.royaltyReceiver != address(0)) {
            transferEth(breakdown.royaltyReceiver, breakdown.royaltyAmount);
        }

        if (breakdown.sellerAmount != 0) {
            transferEth(seller, breakdown.sellerAmount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL ERC20 PAYOUT
    //////////////////////////////////////////////////////////////*/

    function _distributeErc20(
        address paymentToken,
        address payer,
        address treasury,
        address seller,
        MarketplaceTypes.FeeBreakdown memory breakdown
    ) private {
        if (breakdown.marketplaceFee != 0) {
            transferErc20(paymentToken, payer, treasury, breakdown.marketplaceFee);
        }

        if (breakdown.royaltyAmount != 0 && breakdown.royaltyReceiver != address(0)) {
            transferErc20(paymentToken, payer, breakdown.royaltyReceiver, breakdown.royaltyAmount);
        }

        if (breakdown.sellerAmount != 0) {
            transferErc20(paymentToken, payer, seller, breakdown.sellerAmount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                        PAYMENT VALIDATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates native payment amount.
    /// @param expected Expected payment.
    /// @param received msg.value.
    function validateNativePayment(uint256 expected, uint256 received) internal pure {
        if (expected != received) {
            revert MarketplaceErrors.WrongPaymentAmount(expected, received);
        }
    }

    /// @notice Validates ERC20 payment.
    /// @param received msg.value.
    function validateERC20Payment(uint256 received) internal pure {
        if (received != 0) {
            revert MarketplaceErrors.WrongPaymentAmount(0, received);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    ESCROW BID
    //////////////////////////////////////////////////////////////*/

    /// @notice Escrows a bid amount.
    /// @param paymentToken Payment token.
    /// @param bidder Bidder.
    /// @param amount Bid amount.
    /// @param received msg.value

    function escrowBid(address paymentToken, address bidder, uint256 amount, uint256 received) internal {
        if (isNativeToken(paymentToken)) {
            validateNativePayment(amount, received);
            return;
        }

        validateERC20Payment(received);

        IERC20(paymentToken).safeTransferFrom(bidder, address(this), amount);
    }

    /*//////////////////////////////////////////////////////////////
                    ESCROWED AUCTION SETTLEMENT
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                        RELEASE NFT
    //////////////////////////////////////////////////////////////*/

    function releaseERC721(address nft, address to, uint256 tokenId) internal {
        IERC721(nft).safeTransferFrom(address(this), to, tokenId);
    }

    /// @notice Distributes escrowed auction funds.
    /// @dev
    /// Funds are already held by the marketplace contract.
    /// No transferFrom() calls are performed.
    ///
    /// @param paymentToken Payment token.
    /// @param treasury Treasury address.
    /// @param seller Seller address.
    /// @param breakdown Payment breakdown.
    function settleEscrowedAuction(
        address paymentToken,
        address treasury,
        address seller,
        MarketplaceTypes.FeeBreakdown memory breakdown
    ) internal {
        if (isNativeToken(paymentToken)) {
            _settleEscrowedEth(treasury, seller, breakdown);
        } else {
            _settleEscrowedErc20(paymentToken, treasury, seller, breakdown);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL ESCROW ETH
    //////////////////////////////////////////////////////////////*/

    function _settleEscrowedEth(address treasury, address seller, MarketplaceTypes.FeeBreakdown memory breakdown)
        private
    {
        if (breakdown.marketplaceFee != 0) {
            transferEth(treasury, breakdown.marketplaceFee);
        }

        if (breakdown.royaltyAmount != 0 && breakdown.royaltyReceiver != address(0)) {
            transferEth(breakdown.royaltyReceiver, breakdown.royaltyAmount);
        }

        if (breakdown.sellerAmount != 0) {
            transferEth(seller, breakdown.sellerAmount);
        }
    }

    /*//////////////////////////////////////////////////////////////
                INTERNAL ESCROW ERC20
    //////////////////////////////////////////////////////////////*/

    function _settleEscrowedErc20(
        address paymentToken,
        address treasury,
        address seller,
        MarketplaceTypes.FeeBreakdown memory breakdown
    ) private {
        IERC20 token = IERC20(paymentToken);

        if (breakdown.marketplaceFee != 0) {
            token.safeTransfer(treasury, breakdown.marketplaceFee);
        }

        if (breakdown.royaltyAmount != 0 && breakdown.royaltyReceiver != address(0)) {
            token.safeTransfer(breakdown.royaltyReceiver, breakdown.royaltyAmount);
        }

        if (breakdown.sellerAmount != 0) {
            token.safeTransfer(seller, breakdown.sellerAmount);
        }
    }
}

