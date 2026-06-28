import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";
import { PoolClient } from "pg";

function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleLazyMintPurchase(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    if (!args || !meta) return;

    const { nft, tokenId, buyer, creator, amount } = args;

    const contract = normalize(nft)!;
    const tokenIdStr = tokenId.toString();
    const buyerAddr = normalize(buyer)!;
    const creatorAddr = normalize(creator)!;
    const priceStr = amount?.toString() || "0";

    const txHash = meta.txHash || meta.transactionHash;

    await storeActivity(
      "LAZY_MINT_SALE",
      contract,
      tokenIdStr,
      creatorAddr,
      buyerAddr,
      priceStr,
      txHash,
      meta.blockNumber,
      meta.logIndex,
      client
    );

    const pipe = redis.pipeline();
    pipe.del(`nft:${contract}:${tokenIdStr}`);
    pipe.del(`collection:full:${contract}`);
    await pipe.exec();

  } catch (err) {
    console.error("❌ LazyMintPurchase error:", err);
    throw err;
  }
}