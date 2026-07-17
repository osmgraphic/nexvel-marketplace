// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

/*//////////////////////////////////////////////////////////////
                        UUPS PROXY
//////////////////////////////////////////////////////////////*/
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/*//////////////////////////////////////////////////////////////
                        ERC1155
//////////////////////////////////////////////////////////////*/
import {NexvelERC1155Upgradeable} from "../../src/marketplace/NexvelERC1155Upgradeable.sol";

/*//////////////////////////////////////////////////////////////
                        REGISTRY
//////////////////////////////////////////////////////////////*/
import {IRegistry} from "../../src/marketplace/registry/IRegistry.sol";

contract DeployERC1155 is Script {
    function run() external returns (address erc1155Proxy) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address admin = vm.envAddress("ADMIN_ADDRESS");
        address operator = vm.envAddress("OPERATOR_ADDRESS");
        address registryAddr = vm.envAddress("REGISTRY_ADDRESS");

        require(admin != address(0), "Admin zero");
        require(operator != address(0), "Operator zero");
        require(registryAddr != address(0), "Registry zero");

        IRegistry registry = IRegistry(registryAddr);

        /*//////////////////////////////////////////////////////////////
                               CREATORS (FROM.env)
        //////////////////////////////////////////////////////////////*/
        address[] memory creators = new address[](5);
        creators[0] = vm.envAddress("CREATOR_1");
        creators[1] = vm.envAddress("CREATOR_2");
        creators[2] = vm.envAddress("CREATOR_3");
        creators[3] = vm.envAddress("CREATOR_4");
        creators[4] = vm.envAddress("CREATOR_5");

        vm.startBroadcast(deployerKey);

        /*//////////////////////////////////////////////////////////////
                        DEPLOY IMPLEMENTATION
        //////////////////////////////////////////////////////////////*/
        NexvelERC1155Upgradeable impl = new NexvelERC1155Upgradeable();

        /*//////////////////////////////////////////////////////////////
                ENCODE INITIALIZER (SECURE METHOD)
        //////////////////////////////////////////////////////////////*/
        bytes memory initData = abi.encodeWithSelector(
            NexvelERC1155Upgradeable.initialize.selector,
            "ipfs://", // baseURI
            registryAddr, // registry
            admin,
            operator,
            creators
        );

        /*//////////////////////////////////////////////////////////////
                        DEPLOY PROXY (SAFE)
        //////////////////////////////////////////////////////////////*/
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        erc1155Proxy = address(proxy);

        /*//////////////////////////////////////////////////////////////
                        REGISTRY WIRING
        //////////////////////////////////////////////////////////////*/
        registry.setERC1155(erc1155Proxy);

        vm.stopBroadcast();

        /*//////////////////////////////////////////////////////////////
                            LOGS
        //////////////////////////////////////////////////////////////*/
        console2.log("======================================");
        console2.log("NEXVEL ERC1155 DEPLOYED");
        console2.log("======================================");
        console2.log("Proxy         :", erc1155Proxy);
        console2.log("Implementation:", address(impl));
        console2.log("Registry      :", registryAddr);
        console2.log("Registered    : YES");
    }
}
