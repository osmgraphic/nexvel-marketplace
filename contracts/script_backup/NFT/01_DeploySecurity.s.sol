// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {NexvelSecurityImpl} from "../../src/marketplace/security/NexvelSecurityImpl.sol";
import {IRegistry} from "../../src/marketplace/registry/IRegistry.sol";

contract DeploySecurity is Script {
    function run() external returns (address securityProxy) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address admin = vm.envAddress("ADMIN_ADDRESS");
        address operator = vm.envAddress("OPERATOR_ADDRESS");
        address registry = vm.envAddress("REGISTRY_ADDRESS");

        address[] memory creators = new address[](5);
        creators[0] = vm.envAddress("CREATOR_1");
        creators[1] = vm.envAddress("CREATOR_2");
        creators[2] = vm.envAddress("CREATOR_3");
        creators[3] = vm.envAddress("CREATOR_4");
        creators[4] = vm.envAddress("CREATOR_5");

        vm.startBroadcast(deployerKey);

        // Deploy implementation
        NexvelSecurityImpl impl = new NexvelSecurityImpl();

        // Encode initializer
        bytes memory initData =
            abi.encodeWithSelector(NexvelSecurityImpl.initialize.selector, admin, operator, registry, creators);

        // Deploy proxy
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        securityProxy = address(proxy);

        // ✅ Register in Registry
        IRegistry(registry).setSecurity(securityProxy);

        vm.stopBroadcast();

        console2.log("==================================");
        console2.log("NEXVEL SECURITY DEPLOYED");
        console2.log("==================================");
        console2.log("Proxy         :", securityProxy);
        console2.log("Implementation:", address(impl));
        console2.log("Registry      :", registry);
        console2.log("Registered    : YES");
    }
}
