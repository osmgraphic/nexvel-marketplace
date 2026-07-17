import { useWriteContract } from 'wagmi'
import { parseUnits } from 'viem'
import StakingABI from '../constants/staking.js'

const stakingPoolAddress = import.meta.env.VITE_STAKING_ADDRESS;

export function useStake() {
  const { writeContractAsync } = useWriteContract()

  const stake = async (amount, tierId, workingStatus) => {
    return writeContractAsync({
      address: stakingPoolAddress,
      abi: StakingABI,
      functionName: 'stake',
      args: [
        parseUnits(amount, 18),
        tierId,
        workingStatus
      ]
    })
  }

  return { stake }
}

export default useStake();
