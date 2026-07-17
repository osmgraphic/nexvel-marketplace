import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleFundsClaimed(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ FundsClaimed skipped: missing args/meta");
      return;
    }

    const { saleId, creator, creatorAmount } = args;

    if (!saleId || !creator) {
      console.warn("⚠️ FundsClaimed skipped: invalid data");
      return;
    }

    const creatorAddr = normalize(creator)!;
    const saleIdStr = saleId.toString();
    const amountStr = creatorAmount?.toString() || "0";

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "LAUNCHPAD_FUNDS",
      null,               // ✅ no contract
      saleIdStr,
      creatorAddr,
      creatorAddr,
      amountStr,
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
    pipe.del(`user:portfolio:${creatorAddr}`);

    await pipe.exec();

    console.log("💰 Funds claimed:", saleIdStr, amountStr);

  } catch (err) {
    console.error("❌ handleFundsClaimed:", {
      saleId: args?.saleId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}