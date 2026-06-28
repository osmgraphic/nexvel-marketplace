// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {NexvelSecurityImpl} from "../../src/marketplace/security/NexvelSecurityImpl.sol";

contract DeploySecurity is Script {
    function run() external returns (address securityProxy) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address admin = vm.envAddress("ADMIN_ADDRESS");
        address operator = vm.envAddress("OPERATOR_ADDRESS");
        address registry = vm.envAddress("REGISTRY_ADDRESS");

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
        NexvelSecurityImpl impl = new NexvelSecurityImpl();

        /*//////////////////////////////////////////////////////////////
                            INITIALIZER DATA
        //////////////////////////////////////////////////////////////*/
        bytes memory initData =
            abi.encodeWithSelector(NexvelSecurityImpl.initialize.selector, admin, operator, registry, creators);

        /*//////////////////////////////////////////////////////////////
                            UUPS PROXY
        //////////////////////////////////////////////////////////////*/
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        securityProxy = address(proxy);

        vm.stopBroadcast();

        /*//////////////////////////////////////////////////////////////
                            LOGS
        //////////////////////////////////////////////////////////////*/
        console2.log("=== NEXVEL SECURITY DEPLOYED (UUPS) ===");
        console2.log("Security Proxy :", securityProxy);
        console2.log("Security Impl  :", address(impl));
        console2.log("Admin          :", admin);
        console2.log("Operator       :", operator);
        console2.log("Registry       :", registry);
        console2.log("Creator 1      :", creators[0]);
        console2.log("Creator 2      :", creators[1]);
        console2.log("Creator 3      :", creators[2]);
        console2.log("Creator 4      :", creators[3]);
        console2.log("Creator 5      :", creators[4]);
    }
}
