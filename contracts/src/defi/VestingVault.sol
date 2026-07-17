// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// -------------------------------------------------------
// 🔹 OpenZeppelin v5 Upgradeable
// -------------------------------------------------------
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title VestingVault
/// @notice Production-grade ERC20 vesting vault with TGE + cliff + daily linear vesting
/// @dev UUPS upgradeable, single-token vault
contract VestingVault is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuard, PausableUpgradeable {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotAuthorized();
    error InvalidSchedule();
    error NothingToClaim();
    error InvalidAmount();
    error InvalidAddress();

    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    IERC20 public token; // Vesting token (NXV)
    address public governor; // DAO governor

    struct VestingSchedule {
        bool initialized;
        address beneficiary;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 tgePercentage; // 0–100
        uint64 start;
        uint64 cliff;
        uint64 durationDays; // linear vesting duration (days)
        uint64 lastClaim;
    }

    uint256 public nextScheduleId;
    mapping(uint256 => VestingSchedule) public schedules;
    mapping(address => uint256[]) public schedulesByBeneficiary;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event GovernorUpdated(address indexed newGovernor);
    event VestingScheduleCreated(
        uint256 indexed scheduleId,
        address indexed beneficiary,
        uint256 totalAmount,
        uint256 tgePercentage,
        uint64 start,
        uint64 cliff,
        uint64 durationDays
    );
    event VestingClaimed(uint256 indexed scheduleId, address indexed beneficiary, uint256 amount, uint256 totalClaimed);
    event VestingScheduleCancelled(uint256 indexed scheduleId);

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/
    function _onlyAdmin() internal view {
        if (msg.sender != owner() && msg.sender != governor) {
            revert NotAuthorized();
        }
    }

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(address _token, address _governor) public initializer {
        if (_token == address(0) || _governor == address(0)) {
            revert InvalidAddress();
        }

        __Ownable_init(msg.sender);
        __Pausable_init();

        token = IERC20(_token);
        governor = _governor;
        nextScheduleId = 1;
    }

    /*//////////////////////////////////////////////////////////////
                        CREATE VESTING SCHEDULE
    //////////////////////////////////////////////////////////////*/

    function createVestingSchedule(
        address beneficiary,
        uint256 totalAmount,
        uint256 tgePercentage,
        uint64 start,
        uint64 cliff,
        uint64 durationDays
    ) external onlyAdmin returns (uint256 scheduleId) {
        if (beneficiary == address(0) || totalAmount == 0 || tgePercentage > 100 || cliff < start || durationDays == 0)
        {
            revert InvalidAmount();
        }

        // Prevent over-commitment
        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient vault balance");

        scheduleId = nextScheduleId++;

        schedules[scheduleId] = VestingSchedule({
            initialized: true,
            beneficiary: beneficiary,
            totalAmount: totalAmount,
            claimedAmount: 0,
            tgePercentage: tgePercentage,
            start: start,
            cliff: cliff,
            durationDays: durationDays,
            lastClaim: 0
        });

        schedulesByBeneficiary[beneficiary].push(scheduleId);

        emit VestingScheduleCreated(scheduleId, beneficiary, totalAmount, tgePercentage, start, cliff, durationDays);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW: RELEASABLE AMOUNT
    //////////////////////////////////////////////////////////////*/

    function getReleasableAmount(uint256 scheduleId) public view returns (uint256) {
        VestingSchedule memory s = schedules[scheduleId];
        if (!s.initialized) revert InvalidSchedule();

        uint256 nowTs = block.timestamp;
        if (nowTs < s.start) return 0;

        uint256 tgeAmount = (s.totalAmount * s.tgePercentage) / 100;
        uint256 unlocked = tgeAmount;

        if (nowTs >= s.cliff) {
            uint256 vestedDays = (nowTs - s.cliff) / 1 days;
            if (vestedDays > s.durationDays) {
                vestedDays = s.durationDays;
            }

            uint256 linearAmount = ((s.totalAmount - tgeAmount) * vestedDays) / s.durationDays;

            unlocked += linearAmount;
        }

        if (unlocked > s.totalAmount) {
            unlocked = s.totalAmount;
        }

        return unlocked - s.claimedAmount;
    }

    /*//////////////////////////////////////////////////////////////
                        CLAIM TOKENS
    //////////////////////////////////////////////////////////////*/

    function claim(uint256 scheduleId) external nonReentrant whenNotPaused {
        VestingSchedule storage s = schedules[scheduleId];
        if (!s.initialized) revert InvalidSchedule();
        if (msg.sender != s.beneficiary) revert NotAuthorized();

        uint256 amount = getReleasableAmount(scheduleId);
        if (amount == 0) revert NothingToClaim();

        s.claimedAmount += amount;
        s.lastClaim = uint64(block.timestamp);

        token.safeTransfer(msg.sender, amount);

        emit VestingClaimed(scheduleId, msg.sender, amount, s.claimedAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        ADMIN CONTROLS
    //////////////////////////////////////////////////////////////*/

    function setGovernor(address newGovernor) external onlyOwner {
        if (newGovernor == address(0)) revert InvalidAddress();
        governor = newGovernor;
        emit GovernorUpdated(newGovernor);
    }

    function cancelSchedule(uint256 scheduleId) external onlyAdmin {
        VestingSchedule storage s = schedules[scheduleId];
        if (!s.initialized) revert InvalidSchedule();

        uint256 remaining = s.totalAmount - s.claimedAmount;
        delete schedules[scheduleId];

        token.safeTransfer(owner(), remaining);

        emit VestingScheduleCancelled(scheduleId);
    }

    function rescueTokens(address _token, uint256 amount, address to) external onlyOwner {
        if (_token == address(0) || to == address(0) || amount == 0) {
            revert InvalidAddress();
        }
        require(_token != address(token), "Cannot withdraw vesting token");

        IERC20(_token).safeTransfer(to, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE CONTROL
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                        UUPS AUTHORIZATION
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
