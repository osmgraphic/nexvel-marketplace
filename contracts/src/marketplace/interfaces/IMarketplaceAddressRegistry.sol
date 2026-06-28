// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IMarketplaceAddressRegistry {
    function security() external view returns (address);
    function marketplace() external view returns (address);
    function launchpad() external view returns (address);
    function erc1155() external view returns (address);
    function nftFactory() external view returns (address);
}
