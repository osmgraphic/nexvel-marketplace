// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    IERC20 public immutable TOKEN;
    bytes32 public immutable MERKLE_ROOT;

    mapping(address => bool) public claimed;

    event Claimed(address indexed user, uint256 amount);

    constructor(address _token, bytes32 _root) {
        require(_token != address(0), "Invalid token");
        require(_root != bytes32(0), "Invalid merkle root");

        TOKEN = IERC20(_token);
        MERKLE_ROOT = _root;
    }

    function claim(uint256 amount, bytes32[] calldata proof) external {
        require(amount > 0, "Zero amount");
        require(!claimed[msg.sender], "Already claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

        require(MerkleProof.verify(proof, MERKLE_ROOT, leaf), "Invalid proof");

        claimed[msg.sender] = true;

        TOKEN.safeTransfer(msg.sender, amount);

        emit Claimed(msg.sender, amount);
    }
}
