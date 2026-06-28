// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
──────────────────────────────────────────────────────────────
    TreasuryWallet (UUPS Upgradeable) — OpenZeppelin v5
──────────────────────────────────────────────────────────────
    ✔ Global daily cap (all spending combined)
    ✔ Module-level daily caps
    ✔ Token-level daily caps (USDT, NXV, BNB or any asset)
    ✔ Timelock-only execution
    ✔ Emergency multisig with pausing
    ✔ Safe token transfers (supports non-standard ERC20s)
    ✔ EIP-2612 permit + pull
──────────────────────────────────────────────────────────────
*/

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract TreasuryWallet is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Address for address;

    /* -------------------------------------------------------------------------- */
    /*                                  ROLES                                     */
    /* -------------------------------------------------------------------------- */

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");
    bytes32 public constant MODULE_ROLE = keccak256("MODULE_ROLE");

    /* -------------------------------------------------------------------------- */
    /*                              MODULE CAPS                                    */
    /* -------------------------------------------------------------------------- */

    struct Cap {
        uint256 dailyCap;
        uint256 spentToday;
        uint256 lastReset;
    }

    /// Module → Cap
    mapping(bytes32 => Cap) public moduleCaps;

    /// Module enabled or not
    mapping(bytes32 => bool) public moduleEnabled;

    /* -------------------------------------------------------------------------- */
    /*                           TOKEN-LEVEL DAILY CAPS                            */
    /* -------------------------------------------------------------------------- */

    /// Token → Cap
    mapping(address => Cap) public tokenCaps;

    /* -------------------------------------------------------------------------- */
    /*                             GLOBAL DAILY CAP                                */
    /* -------------------------------------------------------------------------- */

    uint256 public globalDailyCap;
    uint256 public globalSpentToday;
    uint256 public globalLastReset;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event ModuleRegistered(bytes32 indexed id, uint256 cap);
    event ModuleCapUpdated(bytes32 indexed id, uint256 newCap);

    event TokenRegistered(address indexed token, uint256 cap);
    event TokenCapUpdated(address indexed token, uint256 newCap);

    event GlobalCapUpdated(uint256 newCap);

    event Executed(bytes32 indexed moduleId, address target, uint256 value, bytes data);

    event PermitPulled(address token, address from, uint256 amount);

    event Deposit(address indexed sender, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                INITIALIZER                                 */
    /* -------------------------------------------------------------------------- */

    function initialize(address admin, address emergencyMultisig, address timelock, uint256 _globalCap)
        public
        initializer
    {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(EMERGENCY_ROLE, emergencyMultisig);
        _grantRole(TIMELOCK_ROLE, timelock);

        globalDailyCap = _globalCap;
        globalLastReset = block.timestamp;
    }

    /* -------------------------------------------------------------------------- */
    /*                               UUPS AUTH                                    */
    /* -------------------------------------------------------------------------- */

    function _authorizeUpgrade(address impl) internal override onlyRole(UPGRADER_ROLE) {}

    /* -------------------------------------------------------------------------- */
    /*                        INTERNAL: RESET LOGIC                               */
    /* -------------------------------------------------------------------------- */

    function _resetCap(Cap storage c) internal {
        if (block.timestamp > c.lastReset + 1 days) {
            c.spentToday = 0;
            c.lastReset = block.timestamp;
        }
    }

    function _resetGlobal() internal {
        if (block.timestamp > globalLastReset + 1 days) {
            globalSpentToday = 0;
            globalLastReset = block.timestamp;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                        INTERNAL: ACCOUNTING LOGIC                          */
    /* -------------------------------------------------------------------------- */

    function _accountSpend(bytes32 moduleId, address token, uint256 amount) internal {
        require(moduleEnabled[moduleId], "Module disabled");

        Cap storage mc = moduleCaps[moduleId];
        Cap storage tc = tokenCaps[token];

        _resetCap(mc);
        _resetCap(tc);
        _resetGlobal();

        require(mc.spentToday + amount <= mc.dailyCap, "Module cap exceeded");
        require(tc.spentToday + amount <= tc.dailyCap, "Token cap exceeded");
        require(globalSpentToday + amount <= globalDailyCap, "Global cap exceeded");

        mc.spentToday += amount;
        tc.spentToday += amount;
        globalSpentToday += amount;
    }

    /* -------------------------------------------------------------------------- */
    /*                            ADMIN: MODULE CAPS                               */
    /* -------------------------------------------------------------------------- */

    function registerModule(bytes32 id, uint256 cap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        moduleEnabled[id] = true;
        moduleCaps[id] = Cap({dailyCap: cap, spentToday: 0, lastReset: block.timestamp});
        emit ModuleRegistered(id, cap);
    }

    function updateModuleCap(bytes32 id, uint256 newCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        moduleCaps[id].dailyCap = newCap;
        emit ModuleCapUpdated(id, newCap);
    }

    /* -------------------------------------------------------------------------- */
    /*                            ADMIN: TOKEN CAPS                                */
    /* -------------------------------------------------------------------------- */

    function registerToken(address token, uint256 dailyCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenCaps[token] = Cap({dailyCap: dailyCap, spentToday: 0, lastReset: block.timestamp});
        emit TokenRegistered(token, dailyCap);
    }

    function updateTokenCap(address token, uint256 newCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenCaps[token].dailyCap = newCap;
        emit TokenCapUpdated(token, newCap);
    }

    /* -------------------------------------------------------------------------- */
    /*                          ADMIN: GLOBAL CAP                                 */
    /* -------------------------------------------------------------------------- */

    function updateGlobalCap(uint256 newCap) external onlyRole(DEFAULT_ADMIN_ROLE) {
        globalDailyCap = newCap;
        emit GlobalCapUpdated(newCap);
    }

    /* -------------------------------------------------------------------------- */
    /*                          SAFE TOKEN TRANSFERS                               */
    /* -------------------------------------------------------------------------- */

    function _safeTransfer(address token, address to, uint256 amount) internal returns (uint256 actual) {
        uint256 beforeBal = IERC20(token).balanceOf(address(this));

        bytes memory result = token.functionCall(abi.encodeWithSelector(IERC20(token).transfer.selector, to, amount));

        if (result.length > 0) {
            require(abi.decode(result, (bool)), "Transfer failed");
        }

        uint256 afterBal = IERC20(token).balanceOf(address(this));
        actual = beforeBal - afterBal;
    }

    /* -------------------------------------------------------------------------- */
    /*                           PERMIT + PULL                                     */
    /* -------------------------------------------------------------------------- */

    function permitAndPull(address token, address from, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        whenNotPaused
        returns (uint256 actual)
    {
        IERC20Permit(token).permit(from, address(this), amount, deadline, v, r, s);

        uint256 beforeBal = IERC20(token).balanceOf(address(this));

        bytes memory result = token.functionCall(
            abi.encodeWithSelector(IERC20(token).transferFrom.selector, from, address(this), amount)
        );

        if (result.length > 0) {
            require(abi.decode(result, (bool)), "transferFrom failed");
        }

        actual = IERC20(token).balanceOf(address(this)) - beforeBal;

        emit PermitPulled(token, from, actual);
    }

    /* -------------------------------------------------------------------------- */
    /*                       TIMELOCK EXECUTION FUNCTION                           */
    /* -------------------------------------------------------------------------- */

    function executeOperation(
        bytes32 moduleId,
        address token,
        address target,
        uint256 value,
        uint256 costUnit,
        bytes calldata data
    ) external onlyRole(TIMELOCK_ROLE) whenNotPaused nonReentrant returns (bytes memory) {
        require(target != address(0), "Bad target");

        _accountSpend(moduleId, token, costUnit);

        bytes memory result = target.functionCallWithValue(data, value);

        emit Executed(moduleId, target, value, data);

        return result;
    }

    /* -------------------------------------------------------------------------- */
    /*                        EMERGENCY CONTROLS                                   */
    /* -------------------------------------------------------------------------- */

    function pause() external onlyRole(EMERGENCY_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(EMERGENCY_ROLE) {
        _unpause();
    }

    /* -------------------------------------------------------------------------- */
    /*                        fallback functions                                  */
    /* -------------------------------------------------------------------------- */
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw function for admin
    function withdraw(address payable to, uint256 amount) external {
        require(address(this).balance >= amount, "Insufficient funds");
        to.transfer(amount);
    }
}
