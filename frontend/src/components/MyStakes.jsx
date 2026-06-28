// src/components/MyStakes.jsx
import React, { useState, useEffect } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Button,
  TextField,
  Typography,
  LinearProgress,
  Box,
  Grid,
  Chip,
} from "@mui/material";
import {
  useAccount,
  useReadContract,
  useWriteContract,
  usePublicClient,
} from "wagmi";
import { parseUnits, formatUnits, maxUint256 } from "viem";

import { STAKING_ADDRESS, STAKING_ABI } from "../constants/staking";
import { NXV_ADDRESS, NXV_ABI } from "../constants/token";

// Daily ROI for each tier (basis points) – 1% = 100
const tierDailyRoi = [50, 75, 100]; // 0.5%, 0.75%, 1%
// Lock period days per tier (must match Solidity tiers)
const tierLockDays = [30, 90, 180];

export default function MyStakes() {
  const { address, isConnected } = useAccount();

  const [amount, setAmount] = useState("");
  const [tierId, setTierId] = useState(0);
  const [stakes, setStakes] = useState([]);
  const [rewards, setRewards] = useState({});
  const [totalStaked, setTotalStaked] = useState(0);

  const publicClient = usePublicClient();

  // -------------------------------
  // 1) READ ALLOWANCE
  // -------------------------------
  const { data: allowanceRaw } = useReadContract({
    address: NXV_ADDRESS,
    abi: NXV_ABI,
    functionName: "allowance",
    args: address ? [address, STAKING_ADDRESS] : undefined,
    query: {
      enabled: Boolean(address),
      watch: true,
    },
  });

  const allowance = allowanceRaw ? BigInt(allowanceRaw) : 0n;
  const needApproval = allowance === 0n;

  // -------------------------------
  // 2) APPROVE NXV
  // -------------------------------
  const { writeContractAsync: approve } = useWriteContract();

  const handleApprove = async () => {
    try {
      const hash = await approve({
        address: NXV_ADDRESS,
        abi: NXV_ABI,
        functionName: "approve",
        args: [STAKING_ADDRESS, maxUint256],
      });

      const receipt = await publicClient.waitForTransactionReceipt({ hash });
      if (receipt.status !== "success") {
        alert("Approval tx failed on-chain");
        return;
      }

      alert("NXV Approved!");
    } catch (err) {
      console.error(err);
      alert("Approval Failed");
    }
  };

  // -------------------------------
  // 3) STAKE TOKENS
  // -------------------------------
  const { writeContractAsync: stakeNow } = useWriteContract();

const handleStake = async () => {
  if (!amount) {
    alert("Enter amount");
    return;
  }

  if (tierId < 0 || tierId > 2) {
    alert("Tier must be 0, 1, or 2");
    return;
  }

  try {
    console.log("Sending stake tx...");
    const hash = await stakeNow({
      address: STAKING_ADDRESS,
      abi: STAKING_ABI,
      functionName: "stake",
      args: [parseUnits(amount, 18), Number(tierId), true], // isWorking = true
    });

    console.log("Stake tx hash:", hash);

    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    console.log("Stake tx receipt:", receipt);

    if (receipt.status === "reverted") {
      alert("Stake reverted on-chain (failed). Check contract conditions.");
      return;
    }

    alert("Staked Successfully!");
    setAmount("");
  } catch (err) {
    console.error("Stake error:", err);
    alert(err.shortMessage ?? err.message ?? "Staking failed");
  }
};

  // -------------------------------
  // 4) GET USER STAKES
  // -------------------------------
  const { data: stakeData } = useReadContract({
    address: STAKING_ADDRESS,
    abi: STAKING_ABI,
    functionName: "getUserStakes",
    args: address ? [address] : undefined,
    query: {
      enabled: Boolean(address),
      watch: true,
      refetchInterval: 15000, // 15s
    },
  });

  useEffect(() => {
    if (stakeData) {
      setStakes(stakeData);
      const total = stakeData.reduce((acc, s) => {
        const amt = Number(formatUnits(s.amount, 18));
        return acc + amt;
      }, 0);
      setTotalStaked(total);
    } else {
      setStakes([]);
      setTotalStaked(0);
    }
  }, [stakeData]);

  // -------------------------------
  // 5) GET PENDING REWARDS (Auto-refresh)
  // -------------------------------
  useEffect(() => {
    if (!address || !stakes || stakes.length === 0) return;

    const fetchRewards = async () => {
      const newRewards = {};

      for (let i = 0; i < stakes.length; i++) {
        try {
          const reward = await publicClient.readContract({
            address: STAKING_ADDRESS,
            abi: STAKING_ABI,
            functionName: "pendingReward",
            args: [address, BigInt(i)],
          });
          newRewards[i] = Number(formatUnits(reward, 18)).toFixed(4);
        } catch (e) {
          console.error("pendingReward error for index", i, e);
          newRewards[i] = "0";
        }
      }

      setRewards(newRewards);
    };

    fetchRewards();
    const interval = setInterval(fetchRewards, 10000); // every 10s
    return () => clearInterval(interval);
  }, [stakes, address, publicClient]);

  // -------------------------------
  // 6) CLAIM & WITHDRAW
  // -------------------------------
  const { writeContractAsync: claimReward } = useWriteContract();
  const { writeContractAsync: withdraw } = useWriteContract();

  const handleClaim = async (index) => {
    try {
      const hash = await claimReward({
        address: STAKING_ADDRESS,
        abi: STAKING_ABI,
        functionName: "claimReward",
        args: [index, false], // autoCompound = false
      });

      const receipt = await publicClient.waitForTransactionReceipt({ hash });
      if (receipt.status !== "success") {
        alert("Claim tx failed on-chain");
        return;
      }

      alert("Reward claimed!");
    } catch (err) {
      console.error(err);
      alert("Claim failed");
    }
  };

  const handleWithdraw = async (index) => {
    try {
      const hash = await withdraw({
        address: STAKING_ADDRESS,
        abi: STAKING_ABI,
        functionName: "withdraw",
        args: [index],
      });

      const receipt = await publicClient.waitForTransactionReceipt({ hash });
      if (receipt.status !== "success") {
        alert("Withdraw tx failed on-chain");
        return;
      }

      alert("Withdrawn!");
    } catch (err) {
      console.error(err);
      alert("Withdraw failed");
    }
  };

  // -------------------------------
  // Helpers
  // -------------------------------
  const getLockDaysForTier = (tierIndex) =>
    tierLockDays[Number(tierIndex)] ?? 30;

  const getProgress = (startTime, tierIndex) => {
    const now = Date.now() / 1000;
    const elapsed = now - Number(startTime);
    const durationDays = getLockDaysForTier(tierIndex);
    const total = durationDays * 24 * 60 * 60;
    return Math.min((elapsed / total) * 100, 100);
  };

  const getDaysLeft = (startTime, tierIndex) => {
    const now = Date.now() / 1000;
    const elapsed = now - Number(startTime);
    const durationDays = getLockDaysForTier(tierIndex);
    const total = durationDays * 24 * 60 * 60;
    const left = Math.max(total - elapsed, 0);
    return Math.ceil(left / (24 * 60 * 60));
  };

  const getDailyReward = (amount, tierIndex) => {
    const roiBps = tierDailyRoi[Number(tierIndex)] ?? 0;
    const roi = roiBps / 10000;
    return (amount * roi).toFixed(4);
  };

  const getAPY = (tierIndex) => {
    const roiBps = tierDailyRoi[Number(tierIndex)] ?? 0;
    const roi = roiBps / 10000;
    return (roi * 365 * 100).toFixed(2); // %
  };

  // -------------------------------
  // RENDER
  // -------------------------------
  return (
    <Box sx={{ p: 3, bgcolor: "#121212", color: "#fff", minHeight: "100vh" }}>
      {!isConnected ? (
        <Typography>Please connect your wallet</Typography>
      ) : (
        <>
          <Typography variant="h4" gutterBottom>
            Stake NXV
          </Typography>

          <Grid container spacing={2} alignItems="center" sx={{ mb: 3 }}>
            <Grid item>
              <TextField
                label="Amount"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                variant="outlined"
                size="small"
                sx={{ bgcolor: "#1e1e1e", input: { color: "#fff" } }}
              />
            </Grid>
            <Grid item>
              <TextField
                label="Tier (0,1,2)"
                value={tierId}
                onChange={(e) => setTierId(Number(e.target.value))}
                type="number"
                variant="outlined"
                size="small"
                sx={{ bgcolor: "#1e1e1e", input: { color: "#fff" } }}
              />
            </Grid>
            <Grid item>
              {needApproval ? (
                <Button variant="contained" onClick={handleApprove}>
                  Approve NXV
                </Button>
              ) : (
                <Button variant="contained" onClick={handleStake}>
                  Stake
                </Button>
              )}
            </Grid>
          </Grid>

          <Typography variant="h5" gutterBottom sx={{ mt: 3 }}>
            My Stakes (Total Staked: {totalStaked} NXV)
          </Typography>

          {stakes.length === 0 ? (
            <Typography>No Stakes Found</Typography>
          ) : (
            <TableContainer component={Paper} sx={{ bgcolor: "#1e1e1e" }}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Amount (NXV)</TableCell>
                    <TableCell>Tier</TableCell>
                    <TableCell>Start Time</TableCell>
                    <TableCell>Days Left</TableCell>
                    <TableCell>Progress</TableCell>
                    <TableCell>Pending Rewards</TableCell>
                    <TableCell>Daily Reward</TableCell>
                    <TableCell>APY %</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {stakes.map((s, i) => {
                    const amt = Number(formatUnits(s.amount, 18));
                    const tierIndex = Number(s.tierId);

                    return (
                      <TableRow key={i}>
                        <TableCell>{amt}</TableCell>
                        <TableCell>{tierIndex}</TableCell>
                        <TableCell>
                          {new Date(
                            Number(s.startTime) * 1000
                          ).toLocaleString()}
                        </TableCell>
                        <TableCell>
                          {getDaysLeft(s.startTime, tierIndex)} days
                        </TableCell>
                        <TableCell sx={{ width: 150 }}>
                          <LinearProgress
                            variant="determinate"
                            value={getProgress(s.startTime, tierIndex)}
                            sx={{
                              height: 10,
                              borderRadius: 5,
                              bgcolor: "#333",
                              "& .MuiLinearProgress-bar": {
                                bgcolor: "#00e676",
                              },
                            }}
                          />
                        </TableCell>
                        <TableCell>{rewards[i] || "0"}</TableCell>
                        <TableCell>
                          {getDailyReward(amt, tierIndex)}
                        </TableCell>
                        <TableCell>{getAPY(tierIndex)}</TableCell>
                        <TableCell>
                          <Chip
                            label={s.isWorking ? "Working" : "Not Working"}
                            color={s.isWorking ? "success" : "default"}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Button
                            variant="contained"
                            size="small"
                            onClick={() => handleClaim(i)}
                            sx={{ mr: 1 }}
                          >
                            Claim
                          </Button>
                          <Button
                            variant="contained"
                            size="small"
                            onClick={() => handleWithdraw(i)}
                          >
                            Withdraw
                          </Button>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </>
      )}
    </Box>
  );
}
