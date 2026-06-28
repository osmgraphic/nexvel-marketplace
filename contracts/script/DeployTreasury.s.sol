// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TreasuryWallet} from "src/treasury/TreasuryWallet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployTreasury is Script {
    //--------------------------------------------------
    // Environment / Parameters
    //--------------------------------------------------
    address usdt;
    address nxv;
    address bnb;

    // Placeholder token addresses (replace in .env or here)
    function setUp() public {
        usdt = vm.envAddress("USDT_ADDRESS");
        nxv = vm.envAddress("NEXVEL_TOKEN_ADDRESS");
        bnb = vm.envAddress("BNB_ADDRESS");
    }

    function run() external {
        vm.startBroadcast();

        console.log("Deploying Treasury Implementation...");
        TreasuryWallet impl = new TreasuryWallet();

        // Read from .env
        address admin = vm.envAddress("ADMIN");
        address emergencyWallet = vm.envAddress("EMERGENCY_MULTISIG");
        address timelock = vm.envAddress("TIMELOCK_ADDRESS");
        uint256 globalDailyCap = vm.envUint("GLOBAL_DAILY_CAP");

        bytes memory initData = abi.encodeWithSelector(
            TreasuryWallet.initialize.selector, admin, emergencyWallet, timelock, globalDailyCap
        );

        console.log("Deploying Treasury Proxy...");
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        TreasuryWallet treasury = TreasuryWallet(payable(address(proxy)));

        console.log("Treasury deployed at:", address(treasury));

        // --------------------------------------------------
        // Register tokens with placeholder caps
        // --------------------------------------------------
        treasury.registerToken(usdt, 100_000 ether);
        treasury.registerToken(nxv, 500_000 ether);
        treasury.registerToken(bnb, 300 ether);

        console.log("Tokens registered (USDT, NXV, BNB)");

        vm.stopBroadcast();

        console.log("================ Treasury Deployment Complete ================");
        console.log("Proxy Address:", address(treasury));
        console.log("Implementation:", address(impl));

        // after treasury deployed
        uint256 treasuryBalance = IERC20(nxv).balanceOf(address(treasury));
        console.log("Treasury NXV balance:", treasuryBalance);
    }
}
