// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";

// Import your NexvelToken interface
interface INexvelToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FundTreasury is Script {
    address public nxvAddress;
    address public treasuryAddress;
    uint256 public amount; // Amount in wei (18 decimals)
    uint256 public deployerPrivateKey;

    function setUp() public {
        // Load environment variables
        nxvAddress = vm.envAddress("NEXVEL_TOKEN_ADDRESS"); // NXV proxy
        treasuryAddress = vm.envAddress("TREASURY_ADDRESS"); // Treasury proxy
        deployerPrivateKey = vm.envUint("PRIVATE_KEY"); // Admin key

        amount = 1000 ether; // Example: 1000 NXV
    }

    function run() external {
        INexvelToken nxv = INexvelToken(nxvAddress);

        vm.startBroadcast(deployerPrivateKey);

        console2.log("Sending NXV to Treasury...");
        bool success = nxv.transfer(treasuryAddress, amount);
        require(success, "Transfer failed");

        console2.log("Transfer successful!");

        uint256 treasuryBalance = nxv.balanceOf(treasuryAddress);
        console2.log("Treasury NXV balance:", treasuryBalance);

        vm.stopBroadcast();
    }
}
