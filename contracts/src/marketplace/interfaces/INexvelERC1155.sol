// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title INexvelERC1155
 * @notice Interface for Nexvel ERC1155-compatible NFTs
 * @dev Used by Launchpad, Marketplace, and Factory contracts
 */
interface INexvelERC1155 {
    /**
     * @notice Mint ERC1155 token via Launchpad
     * @dev Callable only by authorized Launchpad
     */
    function mintLaunchpad(address to, uint256 id, uint256 amount, string calldata uri) external;

    /**
     * @notice Batch mint ERC1155 tokens via Launchpad
     * @dev Callable only by authorized Launchpad
     */
    function mintBatch1155Launchpad(address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @notice Lazy mint voucher structure for ERC1155
     */
    struct LazyMintVoucher {
        uint256 tokenId;
        uint256 supply;
        uint256 price;
        string uri;
        address creator;
        uint256 nonce;
        uint256 deadline;
        uint256 version;
    }

    /**
     * @notice Lazy mint ERC1155 token using signed voucher
     * @dev Used by Marketplace for gasless minting
     */
    function lazyMint(LazyMintVoucher calldata voucher, bytes calldata signature, uint256 amount, address to) external;

    /*//////////////////////////////////////////////////////////////
                        VOUCHER CONTROL
    //////////////////////////////////////////////////////////////*/

    function cancelAllVouchers() external;
}
