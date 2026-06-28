import { ethers } from "ethers";
import { getMarketplaceContract, getNFTContract } from "./contracts";
import { CONTRACTS } from "../config/contracts";

export const listNFT = async (tokenId, price) => {
  try {
    const nft = await getNFTContract();
    const marketplace = await getMarketplaceContract();

    console.log("Approving NFT...");

    const approveTx = await nft.approve(
      CONTRACTS.MARKETPLACE,
      tokenId
    );
    await approveTx.wait();

    console.log("Listing NFT...");

    const tx = await marketplace.list(
      CONTRACTS.NFT,
      tokenId,
      ethers.parseEther(price),
      ethers.ZeroAddress,
      true
    );

    await tx.wait();

    console.log("✅ NFT Listed!");

  } catch (err) {
    console.error("❌ Listing failed:", err);
  }
};