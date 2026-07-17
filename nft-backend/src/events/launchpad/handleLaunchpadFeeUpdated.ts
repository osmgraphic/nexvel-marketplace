import { PoolClient } from "pg";
import { redis } from "../../utils/redis";
import { storeActivity } from "../activity/activity";

// 🔧 helper
function toStr(v: any) {
  return v !== undefined && v !== null ? v.toString() : null;
}

export async function handleLaunchpadFeeUpdated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ LaunchpadFeeUpdated skipped: missing args/meta");
      return;
    }

    const { newFee } = args;

    if (newFee === undefined || newFee === null) {
      console.warn("⚠️ LaunchpadFeeUpdated skipped: invalid fee");
      return;
    }

    const feeStr = newFee.toString();

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // ⚙️ CONFIG UPSERT (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO launchpad_config (key, value)
      VALUES ('launchpad_fee_bps', $1)
      ON CONFLICT (key)
      DO UPDATE SET value = EXCLUDED.value
      WHERE launchpad_config.value IS DISTINCT FROM EXCLUDED.value
      `,
      [feeStr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "LAUNCHPAD_FEE_UPDATE",
      null,
      "0",
      null,
      null,
      feeStr,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🧹 CACHE INVALIDATION
    // ===============================
    const pipe = redis.pipeline();

    pipe.del("launchpad:config");
    pipe.del("launchpad:settings");

    await pipe.exec();

    console.log("💸 Launchpad fee updated:", feeStr);

  } catch (err) {
    console.error("❌ handleLaunchpadFeeUpdated:", {
      fee: args?.newFee,
      err
    });

    throw err; // 🔥 required for rollback
  }
}