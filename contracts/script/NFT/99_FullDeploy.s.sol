// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

import {ERC1967Proxy} 
    from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MarketplaceAddressRegistry} 
    from "../../src/marketplace/registry/MarketplaceAddressRegistry.sol";

import {NexvelSecurityImpl} 
    from "../../src/marketplace/security/NexvelSecurityImpl.sol";

import {NexvelMarketplace} 
    from "../../src/marketplace/NexvelMarketplace.sol";

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
        address marketplacFeeRecipient = vm.envAddress("MARKETPLACE_FEE_RECIPIENT");
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
        MarketplaceAddressRegistry registry =
            new MarketplaceAddressRegistry(admin);

        /*//////////////////////////////////////////////////////////////
                            SECURITY (UUPS)
        //////////////////////////////////////////////////////////////*/
        NexvelSecurityImpl securityImpl =
            new NexvelSecurityImpl();

        address SECURITY = address(
            new ERC1967Proxy(
                address(securityImpl),
                abi.encodeWithSelector(
                    NexvelSecurityImpl.initialize.selector,
                    admin,
                    operator,
                    address(registry),
                    creators
                )
            )
        );

        /*//////////////////////////////////////////////////////////////
                        MARKETPLACE V3 (DIRECT DEPLOY)
        //////////////////////////////////////////////////////////////*/
        NexvelMarketplaceV3 marketplaceImpl =
            new NexvelMarketplaceV3();

        address MARKETPLACE = address(
            new ERC1967Proxy(
                address(marketplaceImpl),
                abi.encodeWithSelector(
                    NexvelMarketplace.initialize.selector,
                    admin,
                    operator,
                    address(registry),
                    creators,
                    marketplacFeeRecipient,
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

        address LAUNCHPAD = address(
            new ERC1967Proxy(
                address(launchpadImpl),
                abi.encodeWithSelector(
                    NexvelLaunchpad.initialize.selector,
                    admin,
                    operator,
                    address(registry),
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

        address ERC1155 = address(
            new ERC1967Proxy(
                address(erc1155Impl),
                abi.encodeWithSelector(
                    NexvelERC1155Upgradeable.initialize.selector,
                    "ipfs://",
                    address(registry),
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

        address ERC721_IMPL = address(erc721Impl);

        /*//////////////////////////////////////////////////////////////
                    ERC721A IMPLEMENTATION (CLONE TEMPLATE)
        //////////////////////////////////////////////////////////////*/
        NexvelERC721A erc721AImpl =
            new NexvelERC721A();

        address ERC721A_IMPL = address(erc721AImpl);

        /*//////////////////////////////////////////////////////////////
                            FACTORY
        //////////////////////////////////////////////////////////////*/
        address FACTORY = address(
            new NexvelNFTFactory(
                admin,
                address(registry),
                ERC721_IMPL,
                ERC721A_IMPL
            )
        );

        /*//////////////////////////////////////////////////////////////
                            WIRING
        //////////////////////////////////////////////////////////////*/
        registry.setSecurity(SECURITY);
        registry.setMarketplace(MARKETPLACE);
        registry.setLaunchpad(LAUNCHPAD);
        registry.setERC1155(ERC1155);
        registry.setNFTFactory(FACTORY);

        vm.stopBroadcast();

        console2.log("====== NEXVEL FULL DEPLOY (DIRECT V3) ======");
        console2.log("Registry      :", address(registry));
        console2.log("Security      :", SECURITY);
        console2.log("Marketplace   :", MARKETPLACE);
        console2.log("Launchpad     :", LAUNCHPAD);
        console2.log("ERC1155       :", ERC1155);
        console2.log("ERC721 Impl   :", ERC721_IMPL);
        console2.log("ERC721A Impl  :", ERC721A_IMPL);
        console2.log("Factory       :", FACTORY);
    }
}
