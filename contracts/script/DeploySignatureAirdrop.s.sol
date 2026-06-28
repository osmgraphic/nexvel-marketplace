// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {SignatureAirdrop} from "src/defi/SignatureAirdrop.sol";

contract DeploySignatureAirdrop is Script {
    function run() external {
        // Load deployer private key from env
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        SignatureAirdrop airdrop = new SignatureAirdrop(
            "Nexvel Signature Airdrop", // EIP712 name
            "1", // EIP712 version
            admin // DEFAULT_ADMIN_ROLE
        );

        vm.stopBroadcast();

        console.log("SignatureAirdrop deployed at:", address(airdrop));
        console.log("Admin:", admin);
    }
}
