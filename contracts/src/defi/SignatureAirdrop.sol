// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SignatureAirdrop is EIP712, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    // Claim(address user,uint256 amount,uint256 nonce,uint256 expiry,uint256 roundId,address token)
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(address user,uint256 amount,uint256 nonce,uint256 expiry,uint256 roundId,address token)");

    struct Round {
        address token;
        uint256 start;
        uint256 end;
        uint256 maxTotal;
        uint256 claimed;
        bool exists;
        bool paused;
    }

    mapping(uint256 => Round) public rounds;
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public usedNonce; // user -> roundId -> nonce -> used

    event RoundCreated(uint256 indexed roundId, address token, uint256 start, uint256 end, uint256 maxTotal);
    event Claimed(address indexed user, uint256 indexed roundId, address indexed token, uint256 amount, uint256 nonce);

    constructor(string memory name, string memory version, address admin) EIP712(name, version) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function createRound(uint256 roundId, address token, uint256 start, uint256 end, uint256 maxTotal)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(token != address(0), "token=0");
        require(start < end, "start>=end");
        Round storage r = rounds[roundId];
        r.token = token;
        r.start = start;
        r.end = end;
        r.maxTotal = maxTotal;
        r.exists = true;
        r.paused = false;
        emit RoundCreated(roundId, token, start, end, maxTotal);
    }

    function pauseRound(uint256 roundId, bool pause) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(rounds[roundId].exists, "round:not exist");
        rounds[roundId].paused = pause;
    }

    // claim MUST be called by the user wallet (msg.sender == user)
    function claim(uint256 amount, uint256 nonce, uint256 expiry, uint256 roundId, bytes calldata signature)
        external
        nonReentrant
    {
        address user = msg.sender;
        require(block.timestamp <= expiry, "signature expired");

        Round storage r = rounds[roundId];
        require(r.exists, "round not exist");
        require(!r.paused, "round paused");
        require(block.timestamp >= r.start && block.timestamp <= r.end, "round inactive");
        require(amount > 0, "amount=0");
        require(!usedNonce[user][roundId][nonce], "nonce used");
        require(r.claimed + amount <= r.maxTotal, "round cap exceeded");

        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, user, amount, nonce, expiry, roundId, r.token));

        bytes32 digest = _hashTypedDataV4(structHash);
        address recovered = ECDSA.recover(digest, signature);
        require(hasRole(SIGNER_ROLE, recovered), "invalid signer");

        usedNonce[user][roundId][nonce] = true;
        r.claimed += amount;

        IERC20(r.token).safeTransfer(user, amount);

        emit Claimed(user, roundId, r.token, amount, nonce);
    }

    // helper to compute digest off-chain if needed
    function hashClaim(address user, uint256 amount, uint256 nonce, uint256 expiry, uint256 roundId)
        public
        view
        returns (bytes32)
    {
        Round memory r = rounds[roundId];
        require(r.exists, "round not exist");
        bytes32 structHash = keccak256(abi.encode(CLAIM_TYPEHASH, user, amount, nonce, expiry, roundId, r.token));
        return _hashTypedDataV4(structHash);
    }
}
