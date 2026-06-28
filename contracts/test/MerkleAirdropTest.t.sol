// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {MerkleAirdrop} from "../src/defi/MerkleAirdrop.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*//////////////////////////////////////////////////////////////
                        TEST TOKEN
//////////////////////////////////////////////////////////////*/

contract TestToken is ERC20 {
    constructor() ERC20("Test", "TST") {
        _mint(msg.sender, 1_000_000 ether);
    }
}

/*//////////////////////////////////////////////////////////////
                    MERKLE AIRDROP TEST
//////////////////////////////////////////////////////////////*/

contract MerkleAirdropTest is Test {
    using SafeERC20 for IERC20;

    MerkleAirdrop public airdrop;
    TestToken public token;

    bytes32 public constant MERKLE_ROOT = 0xb534ae264e6f898ad6ec2dbd9d9fef1e87846dc9813c7299706ae71e1abd805d;

    function setUp() public {
        token = new TestToken();
        airdrop = new MerkleAirdrop(address(token), MERKLE_ROOT);

        IERC20(address(token)).safeTransfer(address(airdrop), 1_000_000 ether);
    }

    function testClaim() public {
        address user = 0xB741FDBF5815617FC78b7c13A208affC09cBa5e6;
        uint256 amount = 50 ether;

        bytes32[] memory proof = new bytes32[](9);

        bytes32 leaf0 = 0xe201262ff3b58335dcadd0fe0050ed0812d84329f270f4ea619e0443e85614e6;
        bytes32 leaf1 = 0x0de362542550404f7e7a9d0b5f57314666f5cd7af8f724dba76cb1041cb6cf50;
        bytes32 leaf2 = 0xc8c806d2057cdda238f1cabf7f54c4a7e272868606fb0e29e841fc19a2fb7207;
        bytes32 leaf3 = 0x1f73ba52423cd26975059606d53fc9478e50c0c59d5d6d145f29cb9ac2690b07;
        bytes32 leaf4 = 0x865181b644ab929f4ef587087d38715f0f6f90ef54c6e79c149c0f9147fcd559;
        bytes32 leaf5 = 0xf9303408dd9578f2192c37c831da033130318a9bb9b6a2c70dbb6ca453c1b3ba;
        bytes32 leaf6 = 0x321e17845eaf11701fc9c3f8bbd461e7f30396ac3eea028334dcc1a75cf7f252;
        bytes32 leaf7 = 0x7ba7dc0756d7413c0f6304bc64dd4c3f34c7767f2fdce2e7cf6889b8e575b20e;
        bytes32 leaf8 = 0x4bacec413da8cd958ae4712ee21c3342a95ed01e34d0a2c60b1120ebbd12b1b6;

        proof[0] = leaf0;
        proof[1] = leaf1;
        proof[2] = leaf2;
        proof[3] = leaf3;
        proof[4] = leaf4;
        proof[5] = leaf5;
        proof[6] = leaf6;
        proof[7] = leaf7;
        proof[8] = leaf8;

        vm.prank(user);
        airdrop.claim(amount, proof);

        assertEq(token.balanceOf(user), amount);
    }
}
