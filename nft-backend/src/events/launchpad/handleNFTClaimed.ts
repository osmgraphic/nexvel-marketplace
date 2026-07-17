import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleNFTClaimed(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ NFTClaimed skipped: missing args/meta");
      return;
    }

    const { saleId, buyer, quantity } = args;

    if (!saleId || !buyer) {
      console.warn("⚠️ NFTClaimed skipped: invalid data");
      return;
    }

    const buyerAddr = normalize(buyer)!;
    const saleIdStr = saleId.toString();
    const qtyStr = quantity?.toString() || "0";

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "LAUNCHPAD_CLAIM",
      null,
      saleIdStr,
      buyerAddr,
      buyerAddr,
      qtyStr,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🧹 CACHE INVALIDATION
    // ===============================
    const pipe = redis.pipeline();

    pipe.del("launchpad:active");
    pipe.del(`launchpad:sale:${saleIdStr}`);
    pipe.del(`user:portfolio:${buyerAddr}`);

    await pipe.exec();

    console.log("🎁 NFT claimed:", saleIdStr, qtyStr);

  } catch (err) {
    console.error("❌ handleNFTClaimed:", {
      saleId: args?.saleId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}