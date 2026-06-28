// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {NexvelToken} from "src/token/NexvelToken.sol";
import {NexvelTokenv2} from "src/token/NexvelTokenv2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {console} from "forge-std/console.sol";

contract NexvelTokenTest is Test {
    NexvelToken public token;
    NexvelToken public v1;
    NexvelTokenv2 public v2;
    ERC1967Proxy public proxy;

    address public admin = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    address public user1 = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
    address public user2 = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
    address public feeReceiver = address(0x90F79bf6EB2c4f870365E785982E1f101E93b906);

    uint256 public constant INITIAL_SUPPLY = 1_000_000 ether;

    /// OpenZeppelin v5 AccessControl custom error shape
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    // -----------------------------------------------------------
    // Setup: Deploy implementation + Proxy + Initialize
    // -----------------------------------------------------------
    function setUp() public {
        // Deploy logic implementation
        v1 = new NexvelToken();

        // Prepare initializer call data
        bytes memory initData = abi.encodeWithSelector(
            v1.initialize.selector,
            "Nexvel Token",
            "NXV",
            INITIAL_SUPPLY,
            admin,
            feeReceiver,
            100 // 1% fee (basis points)
        );

        // Deploy proxy and initialize through it
        proxy = new ERC1967Proxy(address(v1), initData);

        // Wrap proxy as NexvelToken instance
        token = NexvelToken(address(proxy));
    }

    // -----------------------------------------------------------
    // Initialization test
    // -----------------------------------------------------------
    function test_Initialization() public view {
        assertEq(token.name(), "Nexvel Token");
        assertEq(token.symbol(), "NXV");
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY);
        assertEq(token.feeReceiver(), feeReceiver);
        assertEq(token.transferFee(), 100);
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
    }

    // -----------------------------------------------------------
    // Role access tests
    // -----------------------------------------------------------
    function test_OnlyAdminCanSetFee() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.setTransferFee(200);
        vm.stopPrank();

        vm.startPrank(admin);
        token.setTransferFee(200);
        assertEq(token.transferFee(), 200);
        vm.stopPrank();
    }

    function test_OnlyAdminCanSetFeeReceiver() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.setFeeReceiver(address(0x1234));
        vm.stopPrank();

        vm.startPrank(admin);
        token.setFeeReceiver(address(0x1234));
        assertEq(token.feeReceiver(), address(0x1234));
        vm.stopPrank();
    }

    // -----------------------------------------------------------
    // Mint / burn tests
    // -----------------------------------------------------------
    function test_MintAndBurn_ByRole() public {
        vm.startPrank(admin);
        uint256 mintAmount = 1000 ether;
        token.mint(user1, mintAmount);
        assertEq(token.balanceOf(user1), mintAmount);

        token.burn(user1, 200 ether);
        assertEq(token.balanceOf(user1), 800 ether);
        vm.stopPrank();
    }

    function test_RevertWhen_NonMinterTriesToMint() public {
        vm.startPrank(user1);
        vm.expectRevert();
        token.mint(user1, 100 ether);
        vm.stopPrank();
    }

    // -----------------------------------------------------------
    // Pause/unpause tests
    // -----------------------------------------------------------
    function test_Pause_Unpause() public {
        vm.startPrank(admin);
        token.pause();
        assertTrue(token.paused());

        vm.expectRevert();
        // transfer should revert while paused
        bool success = token.transfer(user1, 10 ether);
        assertFalse(success, "Transfer Should Succeed");

        token.unpause();
        assertFalse(token.paused());
        vm.stopPrank();
    }

    // -----------------------------------------------------------
    // Fee-on-transfer tests
    // -----------------------------------------------------------
    function test_TransferWithFee() public {
        vm.startPrank(admin);
        token.mint(user1, 1000 ether);
        vm.stopPrank();

        vm.startPrank(user1);
        bool success = token.transfer(user2, 1000 ether);
        assertTrue(success, "Transfer Failed");
        vm.stopPrank();

        // 1% fee -> 10 tokens to feeReceiver, 990 to user2
        assertEq(token.balanceOf(user2), 990 ether);
        assertEq(token.balanceOf(feeReceiver), 10 ether);
    }

    function test_TransferWithoutFeeReceiverInvolved() public {
        vm.startPrank(admin);
        token.setTransferFee(200); // 2%
        // transfer from admin (who has initial supply) to feeReceiver should not take fee when receiver is feeReceiver
        bool success = token.transfer(feeReceiver, 1000 ether);
        assertTrue(success, "Transfer Failed");
        vm.stopPrank();

        assertEq(token.balanceOf(feeReceiver), 1000 ether);
    }

    // -----------------------------------------------------------
    // Basic utility test
    // -----------------------------------------------------------
    function test_AdminHasUpgraderRole() public view {
        bool hasRole = token.hasRole(token.UPGRADER_ROLE(), admin);
        console.log("Admin has upgrader role:", hasRole);
    }

    // -----------------------------------------------------------
    // UUPS upgrade authorization test (low-level call)
    // -----------------------------------------------------------
    function test_OnlyUpgraderCanUpgrade() public {
        // Deploy new implementation
        v2 = new NexvelTokenv2();

        // Upgrader (admin) should succeed
        vm.startPrank(admin);
        token.upgradeTo(address(v2));
        vm.stopPrank();

        // Now cast proxy to V2 type
        NexvelTokenv2 tokenv2 = NexvelTokenv2(address(proxy));

        // NonUpgrader (user1) should False
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSelector(AccessControlUnauthorizedAccount.selector, user1, token.UPGRADER_ROLE()));
        token.upgradeTo(address(v2));
        vm.stopPrank();

        // Confirm logic upgrade
        assertEq(tokenv2.version(), "V2");
        assertEq(tokenv2.newFeature(), "New Feature Active");
    }
}
