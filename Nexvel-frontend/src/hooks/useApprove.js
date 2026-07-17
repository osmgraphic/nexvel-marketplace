import { useWriteContract } from 'wagmi'
import { parseUnits } from 'viem'
import NXVTokenABI from '../constants/token.js'

const nxvTokenAddress = import.meta.env.VITE_NEXVEL_TOKEN_ADDRESS;
const stakingPoolAddress = import.meta.env.VITE_STAKING_ADDRESS;

export function useApprove() {
  const { writeContractAsync } = useWriteContract()

  const approve = async (amount) => {
    return writeContractAsync({
      address: nxvTokenAddress,
      abi: NXVTokenABI,
      functionName: 'approve',
      args: [
        stakingPoolAddress,
        parseUnits(amount, 18)
      ],
    })
  }

  return { approve }
}
