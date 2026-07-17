// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title INexvelNFTInitializable
 * @notice Shared initializer interface for ERC721 and ERC721A clones
 * @dev Used only by Factory for cloning + initialization
 */
interface INexvelNFTInitializable {
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_,
        address registry_,
        address operator_,
        address[] calldata creators_,
        uint256 maxSupply_
    ) external;
}
