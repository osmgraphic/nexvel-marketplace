// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IMarketplaceAddressRegistry} from "../interfaces/IMarketplaceAddressRegistry.sol";

abstract contract RegistryConsumer {
    IMarketplaceAddressRegistry public immutable REGISTRY;

    constructor(address registry_) {
        require(registry_ != address(0), "Registry zero");
        REGISTRY = IMarketplaceAddressRegistry(registry_);
    }

    function _onlyMarketplace() internal view {
        require(msg.sender == REGISTRY.marketplace(), "Not marketplace");
    }

    modifier onlyMarketplace() {
        _onlyMarketplace();
        _;
    }

    function _onlyLaunchpad() internal view {
        require(msg.sender == REGISTRY.launchpad(), "Not launchpad");
    }

    modifier onlyLaunchpad() {
        _onlyLaunchpad();
        _;
    }

    function _onlyFactory() internal view {
        require(msg.sender == REGISTRY.nftFactory(), "Not factory");
    }

    modifier onlyFactory() {
        _onlyFactory();
        _;
    }
}
