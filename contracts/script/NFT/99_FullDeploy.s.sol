// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {ERC1967Proxy} 
    from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MarketplaceAddressRegistry}
from "../../src/marketplace/registry/MarketplaceAddressRegistry.sol";

import {IRegistry}
from "../../src/marketplace/registry/IRegistry.sol";

import {NexvelSecurityImpl} 
    from "../../src/marketplace/security/NexvelSecurityImpl.sol";

import {NexvelMarketplaceV3} 
    from "../../src/marketplace/NexvelMarketplaceV3.sol";

import {NexvelLaunchpad} 
    from "../../src/marketplace/NexvelLaunchpad.sol";

import {NexvelERC1155Upgradeable} 
    from "../../src/marketplace/NexvelERC1155Upgradeable.sol";

import {NexvelNFTFactory} 
    from "../../src/marketplace/NexvelNFTFactory.sol";

import {NexvelERC721Impl} 
    from "../../src/marketplace/NexvelERC721Impl.sol";

import {NexvelERC721A} 
    from "../../src/marketplace/NexvelERC721A.sol";

contract FullDeploy is Script {

    function run() external {

        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address admin        = vm.envAddress("ADMIN_ADDRESS");
        address operator     = vm.envAddress("OPERATOR_ADDRESS");
        address marketplaceFeeRecipient = vm.envAddress("MARKETPLACE_FEE_RECIPIENT");
        uint96 marketplaceFeeBps = uint96(vm.envUint("MARKETPLACE_FEE_BPS"));
        address launchpadFeeRecipient = vm.envAddress("LAUNCHPAD_FEE_RECIPIENT");
        uint96 launchpadFeeBps = uint96(vm.envUint("LAUNCHPAD_FEE_BPS"));

        uint256 maxTradeValue    = vm.envUint("MAX_TRADE_VALUE");

        require(admin != address(0), "Admin zero");

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
                            REGISTRY
        //////////////////////////////////////////////////////////////*/
        MarketplaceAddressRegistry deployedRegistry =
          new MarketplaceAddressRegistry(admin);

        IRegistry registry = IRegistry(address(deployedRegistry));

        /*//////////////////////////////////////////////////////////////
                            SECURITY (UUPS)
        //////////////////////////////////////////////////////////////*/
        NexvelSecurityImpl securityImpl =
            new NexvelSecurityImpl();

        address security = address(
            new ERC1967Proxy(
                address(securityImpl),
                abi.encodeWithSelector(
                    NexvelSecurityImpl.initialize.selector,
                    admin,
                    operator,
                    address(deployedRegistry),
                    creators
                )
            )
        );

        /*//////////////////////////////////////////////////////////////
                        MARKETPLACE V3 (DIRECT DEPLOY)
        //////////////////////////////////////////////////////////////*/
        NexvelMarketplaceV3 marketplaceImpl =
            new NexvelMarketplaceV3();

        address marketplace = address(
            new ERC1967Proxy(
                address(marketplaceImpl),
                abi.encodeWithSelector(
                    bytes4(
                        keccak256(
                            "initialize(address,address,address,address[],address,uint96,uint256)"
                        )
                    ),
                    admin,
                    operator,
                    address(deployedRegistry),
                    creators,
                    marketplaceFeeRecipient,
                    marketplaceFeeBps,
                    maxTradeValue
                )
            )
        );

        /*//////////////////////////////////////////////////////////////
                            LAUNCHPAD (UUPS)
        //////////////////////////////////////////////////////////////*/
        NexvelLaunchpad launchpadImpl =
            new NexvelLaunchpad();

        address launchpad = address(
            new ERC1967Proxy(
                address(launchpadImpl),
                abi.encodeWithSelector(
                    NexvelLaunchpad.initialize.selector,
                    admin,
                    operator,
                    address(deployedRegistry),
                    creators,
                    launchpadFeeRecipient,
                    launchpadFeeBps
                )
            )
        );

        /*//////////////////////////////////////////////////////////////
                            ERC1155 (UUPS)
        //////////////////////////////////////////////////////////////*/
        NexvelERC1155Upgradeable erc1155Impl =
            new NexvelERC1155Upgradeable();

        address erc1155 = address(
            new ERC1967Proxy(
                address(erc1155Impl),
                abi.encodeWithSelector(
                    NexvelERC1155Upgradeable.initialize.selector,
                    "ipfs://",
                    address(deployedRegistry),
                    admin,
                    operator,
                    creators
                )
            )
        );

        /*//////////////////////////////////////////////////////////////
                    ERC721 IMPLEMENTATION (CLONE TEMPLATE)
        //////////////////////////////////////////////////////////////*/
        NexvelERC721Impl erc721Impl =
            new NexvelERC721Impl();

        address erc721ImplAddr = address(erc721Impl);

        /*//////////////////////////////////////////////////////////////
                    ERC721A IMPLEMENTATION (CLONE TEMPLATE)
        //////////////////////////////////////////////////////////////*/
        NexvelERC721A erc721AImpl =
            new NexvelERC721A();

        address erc721AImplAddr = address(erc721AImpl);

        /*//////////////////////////////////////////////////////////////
                            FACTORY
        //////////////////////////////////////////////////////////////*/
        address factory = address(
            new NexvelNFTFactory(
                admin,
                address(deployedRegistry),
                erc721ImplAddr,
                erc721AImplAddr
            )
        );

        /*//////////////////////////////////////////////////////////////
                            WIRING
        //////////////////////////////////////////////////////////////*/
        registry.setSecurity(security);
        registry.setMarketplace(marketplace);
        registry.setLaunchpad(launchpad);
        registry.setERC1155(erc1155);
        registry.setNFTFactory(factory);

        require(
            deployedRegistry.isInitialized(),
            "Registry not initialized"
        );

        vm.stopBroadcast();

        console2.log("");

        console2.log("========================================");
        
        console2.log("NEXVEL FULL DEPLOY SUCCESS");
        
        console2.log("========================================");
        console2.log(
          "Registry      :",address(deployedRegistry)
        );
        console2.log("Security      :", security);
        console2.log("Marketplace   :", marketplace);
        console2.log("Launchpad     :", launchpad);
        console2.log("ERC1155       :", erc1155);
        console2.log("ERC721 Impl   :", erc721ImplAddr);
        console2.log("ERC721A Impl  :", erc721AImplAddr);
        console2.log("Factory       :", factory);

        console2.log("");

        console2.log(
          "Registry Initialized :",
          deployedRegistry.isInitialized()
        );
        
        console2.log(
          "Protocol             : Nexvel Marketplace"
        );
        
        console2.log(
          "Version              : 1"
        );
    }
}
