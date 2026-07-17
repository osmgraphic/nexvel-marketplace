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
import {IRegistry} from "../../src/marketplace/registry/IRegistry.sol";

/*//////////////////////////////////////////////////////////////
                        LAUNCHPAD
//////////////////////////////////////////////////////////////*/
import {NexvelLaunchpad} from "../../src/marketplace/NexvelLaunchpad.sol";

contract DeployLaunchpad is Script {
    function run() external returns (address launchpadProxy) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address admin = vm.envAddress("ADMIN_ADDRESS");
        address operator = vm.envAddress("OPERATOR_ADDRESS");
        address registryAddr = vm.envAddress("REGISTRY_ADDRESS");
        address launchpadFeeRecipient = vm.envAddress("LAUNCHPAD_FEE_RECIPIENT");
        uint96 launchpadFeeBps = uint96(vm.envUint("LAUNCHPAD_FEE_BPS"));

        require(registryAddr != address(0), "Registry zero");
        require(launchpadFeeBps <= 1000, "Launchpad fee too high");

        IRegistry registry = IRegistry(registryAddr);

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
        NexvelLaunchpad impl = new NexvelLaunchpad();

        /*//////////////////////////////////////////////////////////////
                        DEPLOY PROXY (NO INIT)
        //////////////////////////////////////////////////////////////*/
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");

        launchpadProxy = address(proxy);

        /*//////////////////////////////////////////////////////////////
                        REGISTER FIRST (CRITICAL)
        //////////////////////////////////////////////////////////////*/
        registry.setLaunchpad(launchpadProxy);

        /*//////////////////////////////////////////////////////////////
                        NOW INITIALIZE
        //////////////////////////////////////////////////////////////*/
        NexvelLaunchpad(payable(launchpadProxy))
            .initialize(admin, operator, registryAddr, creators, launchpadFeeRecipient, launchpadFeeBps);

        vm.stopBroadcast();

        /*//////////////////////////////////////////////////////////////
                            LOGS
        //////////////////////////////////////////////////////////////*/
        console2.log("======================================");
        console2.log("NEXVEL LAUNCHPAD DEPLOYED");
        console2.log("======================================");
        console2.log("Proxy         :", launchpadProxy);
        console2.log("Implementation:", address(impl));
        console2.log("Registry      :", registryAddr);
        console2.log("Registered    : YES");
    }
}
