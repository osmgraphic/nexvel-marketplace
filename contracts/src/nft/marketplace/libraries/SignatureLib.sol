// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {MarketplaceErrors} from "../errors/MarketplaceErrors.sol";

/// @title SignatureLib
/// @author Nexvel
/// @notice Stateless cryptographic helper library for the Nexvel Marketplace.
/// @dev
/// Responsibilities:
/// - Recover ECDSA signers
/// - Verify EIP-191 signatures
/// - Verify EIP-712 signatures
/// - Validate signature deadlines
///
/// This library NEVER:
/// - Reads storage
/// - Performs external calls
/// - Transfers assets
/// - Emits events
/// - Contains marketplace business logic
library SignatureLib {
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                            EIP-191
    //////////////////////////////////////////////////////////////*/

    /// @notice Recovers signer from an Ethereum Signed Message.
    /// @param messageHash Original message hash.
    /// @param signature Signature.
    /// @return signer Recovered signer.
    function recoverSigner(bytes32 messageHash, bytes calldata signature) internal pure returns (address signer) {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(messageHash);

        signer = ECDSA.recover(digest, signature);

        if (signer == address(0)) {
            revert MarketplaceErrors.InvalidSignature();
        }
    }

    /// @notice Verifies an Ethereum Signed Message.
    /// @param expectedSigner Expected signer.
    /// @param messageHash Original message hash.
    /// @param signature Signature.
    function verifySignature(address expectedSigner, bytes32 messageHash, bytes calldata signature) internal pure {
        address recovered = recoverSigner(messageHash, signature);

        if (recovered != expectedSigner) {
            revert MarketplaceErrors.InvalidSignature();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            EIP-712
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns EIP-712 digest.
    /// @param domainSeparator Domain separator.
    /// @param structHash Typed struct hash.
    function hashTypedData(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
    }

    /// @notice Recovers signer from an EIP-712 signature.
    /// @param domainSeparator Domain separator.
    /// @param structHash Typed struct hash.
    /// @param signature Signature.
    /// @return signer Recovered signer.
    function recoverTypedSigner(bytes32 domainSeparator, bytes32 structHash, bytes calldata signature)
        internal
        pure
        returns (address signer)
    {
        bytes32 digest = hashTypedData(domainSeparator, structHash);

        signer = ECDSA.recover(digest, signature);

        if (signer == address(0)) {
            revert MarketplaceErrors.InvalidSignature();
        }
    }

    /// @notice Verifies an EIP-712 signature.
    /// @param expectedSigner Expected signer.
    /// @param domainSeparator Domain separator.
    /// @param structHash Typed struct hash.
    /// @param signature Signature.
    function verifyTypedSignature(
        address expectedSigner,
        bytes32 domainSeparator,
        bytes32 structHash,
        bytes calldata signature
    ) internal pure {
        address recovered = recoverTypedSigner(domainSeparator, structHash, signature);

        if (recovered != expectedSigner) {
            revert MarketplaceErrors.InvalidSignature();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            DEADLINE
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates a signature deadline.
    /// @param deadline Signature deadline.
    function validateDeadline(uint256 deadline) internal view {
        if (deadline != 0 && block.timestamp > deadline) {
            revert MarketplaceErrors.InvalidExpiry();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns Ethereum Signed Message hash.
    /// @param messageHash Original message hash.
    function toEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        return MessageHashUtils.toEthSignedMessageHash(messageHash);
    }

    /// @notice Checks whether signer matches expected signer.
    /// @param signer Recovered signer.
    /// @param expectedSigner Expected signer.
    function validateSigner(address signer, address expectedSigner) internal pure {
        if (signer != expectedSigner) {
            revert MarketplaceErrors.InvalidSignature();
        }
    }
}
