// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title INexvelERC721
 * @notice Interface for Nexvel ERC721-compatible NFT contracts
 * @dev Implemented by Nexvel ERC721 / ERC721A contracts.
 *      This interface is consumed by Marketplace, Launchpad,
 *      and Factory contracts to interact with NFTs in a
 *      standardized and permissioned manner.
 */
interface INexvelERC721 {
    /*//////////////////////////////////////////////////////////////
                            LAUNCHPAD MINTING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint a single ERC721 token via Launchpad
     * @dev Must only be callable by an authorized Launchpad contract.
     *      Used for curated or managed primary sales.
     *
     * @param to  Recipient of the newly minted NFT
     * @param uri Metadata URI assigned to the token
     */
    function mintLaunchpad(address to, string calldata uri) external;

    /**
     * @notice Batch mint multiple ERC721 tokens via Launchpad
     * @dev Allows setting royalty configuration at mint time.
     *      Intended for collection drops and managed releases.
     *
     * @param to               Recipient of all minted tokens
     * @param quantity         Number of tokens to mint
     * @param uri              Base or shared metadata URI
     * @param royaltyReceiver  Address receiving secondary-sale royalties
     * @param royaltyBps       Royalty percentage in basis points
     */
    function mintBatch721Launchpad(
        address to,
        uint256 quantity,
        string calldata uri,
        address royaltyReceiver,
        uint96 royaltyBps
    ) external;

    /*//////////////////////////////////////////////////////////////
                        LAZY MINTING (VOUCHER)
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Lazy mint authorization payload
     * @dev Signed off-chain by an authorized creator.
     *      Consumed on-chain to mint an NFT at purchase time,
     *      enabling gasless listing and deferred minting.
     */

    struct LazyMintVoucher {
        address creator; // Original content creator / signer
        address to; // Intended recipient (or zero for open sale)
        string uri; // Token metadata URI
        uint256 price; // Sale price expected by creator
        uint256 nonce; // Replay protection nonce
        uint256 deadline; // Timestamp after which voucher is invalid
        uint256 version; // must be 1
    }

    /**
     * @notice Mint an ERC721 token using a signed lazy-mint voucher
     * @dev Typically called by the Marketplace contract.
     *      Signature verification and replay protection
     *      are enforced by the implementing contract.
     *
     * @param to         Final recipient of the NFT
     * @param voucher    Lazy mint authorization payload
     * @param signature  Creator's EIP-712 signature
     *
     * @return tokenId   Newly minted token ID
     */
    function lazyMintTo(address to, LazyMintVoucher calldata voucher, bytes calldata signature)
        external
        returns (uint256 tokenId);

    /*//////////////////////////////////////////////////////////////
                        VOUCHER CONTROL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Invalidate all previously issued lazy-mint vouchers
     * @dev Intended as an emergency or administrative safety switch.
     *      Implementations typically use a nonce or versioning scheme.
     */
    function cancelAllVouchers() external;
}
