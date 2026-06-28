// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//-----------------------------------------------------
// 🔹 OpenZeppelin v5 (Upgradeable)
//-----------------------------------------------------
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract StakingPool is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    //---------------------------------------
    // CONSTANTS & PARAMETERS
    //---------------------------------------
    uint256 public constant MIN_DEPOSIT = 5 * 1e18; // $5
    uint256 public constant MAX_DEPOSIT = 10000 * 1e18; // $10,000 max

    uint256 public dailyRoi; // default = 75 (0.75%), set in initialize()

    uint256 public constant WORKING_CAP = 30000; // 3x = 30000 / 10000
    uint256 public constant NONWORKING_CAP = 20000; // 2x = 20000 / 10000

    ERC20Upgradeable public nxv;

    //---------------------------------------
    // TIER SYSTEM
    //---------------------------------------
    struct Tier {
        uint256 lockPeriod; // seconds
        uint256 apr; // APR (basis points, for future use)
    }

    Tier[] public tiers;

    //---------------------------------------
    // USER STAKE DATA
    //---------------------------------------
    struct StakeInfo {
        uint256 amount;
        uint256 lastClaim;
        uint256 totalRewardsClaimed;
        uint256 tierId;
        uint256 startTime; // lock starts at stake time
        bool isWorking;
    }

    mapping(address => StakeInfo[]) public stakes;

    //---------------------------------------
    // EVENTS
    //---------------------------------------
    event Staked(address indexed user, uint256 amount, uint256 tierId, uint256 index);
    event Withdrawn(address indexed user, uint256 amount, uint256 index);
    event RewardPaid(address indexed user, uint256 reward, uint256 index);

    //---------------------------------------
    // INITIALIZER
    //---------------------------------------
    function initialize(address _nxv) external initializer {
        require(_nxv != address(0), "Invalid NXV");

        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();

        nxv = ERC20Upgradeable(_nxv);

        dailyRoi = 75; // 0.75%

        // Default staking tiers
        tiers.push(Tier({lockPeriod: 30 days, apr: 1000})); // Tier 0 = 10% APR
        tiers.push(Tier({lockPeriod: 90 days, apr: 1500})); // Tier 1 = 15% APR
        tiers.push(Tier({lockPeriod: 180 days, apr: 2500})); // Tier 2 = 25% APR
    }

    //---------------------------------------
    // STAKE
    //---------------------------------------
    function stake(uint256 _amount, uint256 _tierId, bool workingStatus) external nonReentrant {
        require(_tierId < tiers.length, "Invalid tier");
        require(_amount >= MIN_DEPOSIT, "Min $5");
        require(_amount <= MAX_DEPOSIT, "Max $10,000");

        require(nxv.transferFrom(msg.sender, address(this), _amount), "TransferFrom failed");

        stakes[msg.sender].push(
            StakeInfo({
                amount: _amount,
                lastClaim: block.timestamp,
                totalRewardsClaimed: 0,
                tierId: _tierId,
                startTime: block.timestamp,
                isWorking: workingStatus
            })
        );

        uint256 index = stakes[msg.sender].length - 1;
        emit Staked(msg.sender, _amount, _tierId, index);
    }

    //---------------------------------------
    // VIEW Array of Stakes of User
    //---------------------------------------
    function getUserStakes(address user) external view returns (StakeInfo[] memory) {
        return stakes[user];
    }

    //---------------------------------------
    // VIEW REWARD
    //---------------------------------------
    function pendingReward(address user, uint256 index) public view returns (uint256) {
        require(index < stakes[user].length, "Invalid index");

        StakeInfo memory s = stakes[user][index];
        if (s.amount == 0) return 0;

        uint256 timeElapsed = block.timestamp - s.lastClaim;
        uint256 dailyReward = (s.amount * dailyRoi) / 10000;

        return (dailyReward * timeElapsed) / 1 days;
    }

    //---------------------------------------
    // CLAIM REWARD
    //---------------------------------------
    function claimReward(uint256 index, bool autoCompound) external nonReentrant {
        require(index < stakes[msg.sender].length, "Invalid index");

        StakeInfo storage s = stakes[msg.sender][index];
        require(s.amount > 0, "No stake");

        uint256 reward = pendingReward(msg.sender, index);
        require(reward > 0, "No rewards");

        uint256 cap = s.isWorking ? WORKING_CAP : NONWORKING_CAP;
        uint256 maxAllowed = (s.amount * cap) / 10000;
        require(s.totalRewardsClaimed + reward <= maxAllowed, "Cap reached");

        s.lastClaim = block.timestamp;
        s.totalRewardsClaimed += reward;

        if (autoCompound) {
            // Auto-compound: add reward to amount
            s.amount += reward;
        } else {
            require(nxv.transfer(msg.sender, reward), "Reward transfer failed");
        }

        emit RewardPaid(msg.sender, reward, index);
    }

    //---------------------------------------
    // WITHDRAW
    //---------------------------------------
    function withdraw(uint256 index) external nonReentrant {
        require(index < stakes[msg.sender].length, "Invalid index");

        StakeInfo storage s = stakes[msg.sender][index];
        require(s.amount > 0, "Already withdrawn");

        Tier memory t = tiers[s.tierId];
        require(block.timestamp >= s.startTime + t.lockPeriod, "Stake still locked");

        uint256 amount = s.amount;
        s.amount = 0;

        require(nxv.transfer(msg.sender, amount), "Transfer failed");

        emit Withdrawn(msg.sender, amount, index);
    }

    //---------------------------------------
    // ADMIN (DAO / TIMELOCK)
    //---------------------------------------
    function addTier(uint256 lockPeriod, uint256 apr) external onlyOwner {
        tiers.push(Tier({lockPeriod: lockPeriod, apr: apr}));
    }

    function setDailyRoi(uint256 newRoi) external onlyOwner {
        require(newRoi > 0 && newRoi <= 1000, "Invalid ROI");
        dailyRoi = newRoi;
    }
}
