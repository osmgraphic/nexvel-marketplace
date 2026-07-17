// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {SignatureAirdrop} from "src/defi/SignatureAirdrop.sol";
import {NexvelToken} from "src/token/NexvelToken.sol";

contract SignatureAirdropTest is Test {
    NexvelToken token;
    SignatureAirdrop airdrop;

    // 🔑 Keys & accounts
    uint256 adminKey;
    uint256 signerKey;
    uint256 userKey;

    address admin;
    address signer;
    address user;

    uint256 constant ROUND_ID = 1;
    uint256 constant CAP = 1000 ether;

    // ------------------------------------------------------------
    // SETUP
    // ------------------------------------------------------------
    function setUp() public {
        adminKey = 0xA11CE;
        signerKey = 0xBEEF;
        userKey = 0xCAFE;

        admin = vm.addr(adminKey);
        signer = vm.addr(signerKey);
        user = vm.addr(userKey);

        // Deploy token
        token = new NexvelToken();

        // Give mint role to test contract (if needed)
        token.grantRole(token.MINTER_ROLE(), address(this));

        // Deploy airdrop
        vm.prank(admin);
        airdrop = new SignatureAirdrop("Nexvel Signature Airdrop", "1", admin);

        // Fund airdrop
        token.mint(address(airdrop), CAP);

        // Grant signer role
        vm.prank(admin);
        airdrop.grantRole(airdrop.SIGNER_ROLE(), signer);

        // Create round
        vm.prank(admin);
        airdrop.createRound(ROUND_ID, address(token), block.timestamp - 1, block.timestamp + 1 days, CAP);

        // Sanity check
        assertEq(token.balanceOf(address(airdrop)), CAP);
    }

    // ------------------------------------------------------------
    // INTERNAL SIGN HELPER
    // ------------------------------------------------------------
    function _signClaim(
        address _user,
        uint256 amount,
        uint256 nonce,
        uint256 expiry,
        uint256 roundId,
        uint256 _signerKey
    ) internal view returns (bytes memory) {
        bytes32 digest = airdrop.hashClaim(_user, amount, nonce, expiry, roundId);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_signerKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // ------------------------------------------------------------
    // POSITIVE TEST
    // ------------------------------------------------------------
    function testValidClaim() public {
        uint256 amount = 100 ether;
        uint256 nonce = 1;
        uint256 expiry = block.timestamp + 1 days;

        bytes memory sig = _signClaim(user, amount, nonce, expiry, ROUND_ID, signerKey);

        vm.prank(user);
        airdrop.claim(amount, nonce, expiry, ROUND_ID, sig);

        assertEq(token.balanceOf(user), amount);
        assertTrue(airdrop.usedNonce(user, ROUND_ID, nonce));
    }

    // ------------------------------------------------------------
    // NEGATIVE TESTS
    // ------------------------------------------------------------
    function testWrongSigner() public {
        uint256 amount = 100 ether;
        uint256 nonce = 2;
        uint256 expiry = block.timestamp + 1 days;

        bytes memory sig = _signClaim(user, amount, nonce, expiry, ROUND_ID, adminKey);

        vm.prank(user);
        vm.expectRevert("invalid signer");
        airdrop.claim(amount, nonce, expiry, ROUND_ID, sig);
    }

    function testWrongAmount() public {
        uint256 amount = 100 ether;
        uint256 nonce = 3;
        uint256 expiry = block.timestamp + 1 days;

        bytes memory sig = _signClaim(user, amount, nonce, expiry, ROUND_ID, signerKey);

        vm.prank(user);
        vm.expectRevert("invalid signer");
        airdrop.claim(amount + 1 ether, nonce, expiry, ROUND_ID, sig);
    }

    function testExpiredSignature() public {
        uint256 amount = 50 ether;
        uint256 nonce = 4;
        uint256 expiry = block.timestamp - 10;

        bytes memory sig = _signClaim(user, amount, nonce, expiry, ROUND_ID, signerKey);

        vm.prank(user);
        vm.expectRevert("signature expired");
        airdrop.claim(amount, nonce, expiry, ROUND_ID, sig);
    }

    function testReplayAttack() public {
        uint256 amount = 10 ether;
        uint256 nonce = 5;
        uint256 expiry = block.timestamp + 1 days;

        bytes memory sig = _signClaim(user, amount, nonce, expiry, ROUND_ID, signerKey);

        vm.prank(user);
        airdrop.claim(amount, nonce, expiry, ROUND_ID, sig);

        vm.prank(user);
        vm.expectRevert("nonce used");
        airdrop.claim(amount, nonce, expiry, ROUND_ID, sig);
    }

    // ------------------------------------------------------------
    // GAS CHECK
    // ------------------------------------------------------------
    function testGasClaim() public {
        uint256 amount = 1 ether;
        uint256 nonce = 6;
        uint256 expiry = block.timestamp + 1 days;

        bytes memory sig = _signClaim(user, amount, nonce, expiry, ROUND_ID, signerKey);

        vm.prank(user);
        uint256 gasBefore = gasleft();
        airdrop.claim(amount, nonce, expiry, ROUND_ID, sig);
        uint256 gasAfter = gasleft();

        emit log_named_uint("gas used (approx)", gasBefore - gasAfter);
    }
}
