// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IRegistry {
    function setSecurity(address security) external;

    function setMarketplace(address marketplace) external;

    function setLaunchpad(address launchpad) external;

    function setERC1155(address erc1155) external;

    function setNFTFactory(address nftFactory) external;
}
