// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

/*//////////////////////////////////////////////////////////////
                        UUPS PROXY
//////////////////////////////////////////////////////////////*/
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/*//////////////////////////////////////////////////////////////
                        REGISTRY
//////////////////////////////////////////////////////////////*/
import {MarketplaceAddressRegistry} from "../../src/marketplace/registry/MarketplaceAddressRegistry.sol";

/*//////////////////////////////////////////////////////////////
                        MARKETPLACE
//////////////////////////////////////////////////////////////*/
import {NexvelMarketplace} from "../../src/marketplace/NexvelMarketplace.sol";

contract DeployMarketplace is Script {
    function run() external returns (address marketplaceProxy) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address admin = vm.envAddress("ADMIN_ADDRESS");
        address operator = vm.envAddress("OPERATOR_ADDRESS");
        address marketplacFeeRecipient = vm.envAddress("MARKETPLACE_FEE_RECIPIENT");
        address registryAddr = vm.envAddress("REGISTRY_ADDRESS");
        uint96 marketplaceFeeBps = uint96(vm.envUint("MARKETPLACE_FEE_BPS"));
        uint256 maxTradeValue_ = vm.envUint("MAX_TRADE_VALUE");

        MarketplaceAddressRegistry registry = MarketplaceAddressRegistry(registryAddr);

        /*//////////////////////////////////////////////////////////////
                            CREATORS (FROM .env)
        //////////////////////////////////////////////////////////////*/
        address[] memory creators = new address[](5);
        creators[0] = vm.envAddress("CREATOR_1");
        creators[1] = vm.envAddress("CREATOR_2");
        creators[2] = vm.envAddress("CREATOR_3");
        creators[3] = vm.envAddress("CREATOR_4");
        creators[4] = vm.envAddress("CREATOR_5");

        vm.startBroadcast(deployerKey);

        /*//////////////////////////////////////////////////////////////
                            IMPLEMENTATION
        //////////////////////////////////////////////////////////////*/
        NexvelMarketplace impl = new NexvelMarketplace();

        /*//////////////////////////////////////////////////////////////
                            INITIALIZER DATA
        //////////////////////////////////////////////////////////////*/
        bytes memory initData = abi.encodeWithSelector(
            NexvelMarketplace.initialize.selector,
            admin,
            operator,
            registry,
            creators,
            marketplacFeeRecipient,
            marketplaceFeeBps,
            maxTradeValue_
        );

        /*//////////////////////////////////////////////////////////////
                            UUPS PROXY
        //////////////////////////////////////////////////////////////*/
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        marketplaceProxy = address(proxy);

        /*//////////////////////////////////////////////////////////////
                            REGISTRY WIRING
        //////////////////////////////////////////////////////////////*/
        registry.setMarketplace(marketplaceProxy);

        vm.stopBroadcast();

        /*//////////////////////////////////////////////////////////////
                            LOGS
        //////////////////////////////////////////////////////////////*/
        console2.log("=== NEXVEL MARKETPLACE V1 DEPLOYED (UUPS) ===");
        console2.log("Marketplace Proxy :", marketplaceProxy);
        console2.log("Marketplace Impl  :", address(impl));
        console2.log("Registry          :", registryAddr);
        console2.log("Admin             :", admin);
    }
}
