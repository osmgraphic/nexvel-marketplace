// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {TokenFactory} from "../src/factory/TokenFactory.sol";
import {console2} from "forge-std/console2.sol";

// Import your ERC20 Token interface
interface INexvelToken {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function admin() external view returns (address);
}

contract CreateToken is Script {
    address factoryAddress;
    address public admin;
    address public feeReceiver_;

    function setUp() public {
        factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        admin = vm.envAddress("ADMIN");
        feeReceiver_ = vm.envAddress("FEE_RECEIVER");
    }

    function run() external {
        TokenFactory factory = TokenFactory(factoryAddress);

        vm.startBroadcast();

        //-----------------------------------------------------
        // 🚀 Create New NXV Token
        //-----------------------------------------------------
        address newToken = factory.createToken(
            "Nexvel Token",
            "NXV",
            1_000_000 ether, // 1,000,000 NXV
            admin, // admin
            feeReceiver_, // fee receiver
            150 // 1.5% fee
        );

        console2.log("======================================");
        console2.log(" New Nexvel Token Created Successfully!");
        console2.log("======================================");
        console2.log("Token Address:", newToken);

        //-----------------------------------------------------
        // 📌 Fetch Token Details
        //-----------------------------------------------------
        INexvelToken nxv = INexvelToken(newToken);

        string memory tokenName = nxv.name();
        string memory tokenSymbol = nxv.symbol();
        uint256 tokenSupply = nxv.totalSupply();

        console2.log("Token Name:", tokenName);
        console2.log("Token Symbol:", tokenSymbol);
        console2.log("Total Supply:", tokenSupply);
        console2.log("Admin Address:", admin);
        console2.log("Fee Receiver:", feeReceiver_);
        console2.log("Fee Percentage (BPS): 150 (1.5%)");

        console2.log("======================================");

        vm.stopBroadcast();
    }
}
