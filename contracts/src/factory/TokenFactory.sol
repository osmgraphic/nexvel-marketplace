// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//------------------------------------------------------
// 🔹 OpenZeppelin v5 Imports
//------------------------------------------------------
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

//------------------------------------------------------
// 🔹 Import NexvelToken (Upgradeable BEP-20)
//------------------------------------------------------
import {NexvelToken} from "../token/NexvelToken.sol"; // Refer latest 2.1 version;

//------------------------------------------------------
// 🔹 TokenFactory Contract
//------------------------------------------------------
contract TokenFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    //--------------------------------------------------
    // 📦 State Variables
    //--------------------------------------------------
    address public implementationAddress; // Base NexvelToken implementation
    address[] public allTokens; // Track all deployed tokens

    //--------------------------------------------------
    // ⚡ Events
    //--------------------------------------------------
    event TokenCreated(
        string name_,
        string symbol_,
        uint256 initialSupply,
        address admin,
        address feeReceiver_,
        uint256 feeBasisPoints_
    );

    //--------------------------------------------------
    // 🔹 Initializer
    //--------------------------------------------------
    function initialize(address _implementationAddress) public initializer {
        require(_implementationAddress != address(0), "Invalid implementation");
        implementationAddress = _implementationAddress;
        _transferOwnership(msg.sender);
    }

    //--------------------------------------------------
    // 🔹 UUPS Authorization
    //--------------------------------------------------
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    //--------------------------------------------------
    // 🏗️ Deploy New Token (Clone Pattern)
    //--------------------------------------------------
    function createToken(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        address admin,
        address feeReceiver_,
        uint256 feeBasisPoints_
    ) external onlyOwner returns (address) {
        // Create clone (minimal proxy) for upgradeable logic
        address clone = Clones.clone(implementationAddress);

        // Initialize the new NexvelToken instance
        NexvelToken(clone).initialize(name_, symbol_, initialSupply, admin, feeReceiver_, feeBasisPoints_);

        // Store and emit
        allTokens.push(clone);
        emit TokenCreated(name_, symbol_, initialSupply, admin, feeReceiver_, feeBasisPoints_);

        return clone;
    }

    //--------------------------------------------------
    // 📜 View Functions
    //--------------------------------------------------
    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }

    function totalTokens() external view returns (uint256) {
        return allTokens.length;
    }
}
