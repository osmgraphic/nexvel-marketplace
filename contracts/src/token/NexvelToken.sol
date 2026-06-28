// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//------------------------------------------------------
// 🔹 OpenZeppelin v5 Upgradeable Imports
//------------------------------------------------------
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    ERC20BurnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {
    ERC20PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {
    ERC20PermitUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {
    ERC20VotesUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

/// @title NexvelToken (Upgradeable BEP-20)
/// @notice Upgradeable governance + fee token with role-based controls
contract NexvelToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    ERC20PermitUpgradeable,
    ERC20VotesUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    //------------------------------------------------------
    // 🔹 Roles
    //------------------------------------------------------
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    //------------------------------------------------------
    // 🔹 Fee Mechanism
    //------------------------------------------------------
    uint256 public transferFee; // in basis points (100 = 1%)
    address public feeReceiver;

    //------------------------------------------------------
    // 🔹 Storage Gap (for upgrades)
    //------------------------------------------------------
    uint256[48] private _gap;

    //------------------------------------------------------
    // 🔹 Initializer
    //------------------------------------------------------
    /// @dev replaces constructor for upgradeable contracts
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        address admin,
        address feeReceiver_,
        uint256 feeBasisPoints_
    ) public initializer {
        require(admin != address(0), "Invalid admin");
        require(feeReceiver_ != address(0), "Invalid fee receiver");
        require(feeBasisPoints_ <= 500, "Fee too high"); // max 5%

        __ERC20_init(name_, symbol_);
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __ERC20Permit_init(name_);
        __ERC20Votes_init();
        __AccessControl_init();
        // ❌ No __UUPSUpgradeable_init() needed in OZ v5

        transferFee = feeBasisPoints_;
        feeReceiver = feeReceiver_;

        // Mint initial supply to admin
        _mint(admin, initialSupply);

        // Grant roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
    }

    //------------------------------------------------------
    // 🔹 Public Helpers
    //------------------------------------------------------
    function version() external pure virtual returns (string memory) {
        return "V1";
    }

    //------------------------------------------------------
    // 🔹 Core Role Functions
    //------------------------------------------------------
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    function setTransferFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee <= 500, "Fee too high");
        transferFee = newFee;
    }

    function setFeeReceiver(address newReceiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newReceiver != address(0), "Invalid receiver");
        feeReceiver = newReceiver;
    }

    //------------------------------------------------------
    // 🔹 UUPS Upgrade Authorization
    //------------------------------------------------------
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    /// Optional public admin upgrade call
    function upgradeTo(address newImplementation) external onlyRole(UPGRADER_ROLE) {
        ERC1967Utils.upgradeToAndCall(newImplementation, bytes(""));
    }

    //------------------------------------------------------
    // 🔹 Fee-on-Transfer (OZ v5 uses _update)
    //------------------------------------------------------
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20PausableUpgradeable, ERC20VotesUpgradeable)
    {
        if (transferFee > 0 && from != address(0) && to != address(0) && from != feeReceiver && to != feeReceiver) {
            uint256 feeAmount = (value * transferFee) / 10_000;
            uint256 sendAmount = value - feeAmount;

            if (feeAmount > 0) {
                super._update(from, feeReceiver, feeAmount);
            }
            if (sendAmount > 0) {
                super._update(from, to, sendAmount);
            }
        } else {
            super._update(from, to, value);
        }
    }

    //------------------------------------------------------
    // 🔹 Handle Nonce Conflict (Permit + Votes)
    //------------------------------------------------------
    function nonces(address owner) public view override(ERC20PermitUpgradeable, NoncesUpgradeable) returns (uint256) {
        return super.nonces(owner);
    }

    //------------------------------------------------------
    // 🔹 ERC20Votes Clock (REQUIRED for Governor)
    //------------------------------------------------------
    function clock() public view override returns (uint48) {
        return uint48(block.number);
    }

    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=blocknumber";
    }
}
