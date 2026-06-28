import { ethers } from "ethers";
import { CONTRACTS } from "../config/contracts";

import MARKETPLACE_ABI from "../abi/marketplace.json";
import NFT_ABI from "../abi/NFT.json";

export const getProvider = () => {
  return new ethers.BrowserProvider(window.ethereum);
};

export const getSigner = async () => {
  const provider = getProvider();
  return await provider.getSigner();
};

export const getMarketplaceContract = async () => {
  const signer = await getSigner();
  return new ethers.Contract(
    CONTRACTS.MARKETPLACE,
    MARKETPLACE_ABI,
    signer
  );
};

export const getNFTContract = async () => {
  const signer = await getSigner();
  return new ethers.Contract(
    CONTRACTS.NFT,
    NFT_ABI,
    signer
  );
};