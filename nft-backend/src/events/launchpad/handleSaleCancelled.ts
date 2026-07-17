import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleSaleCancelled(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ SaleCancelled skipped: missing args/meta");
      return;
    }

    const { saleId, cancelledBy } = args;

    if (!saleId) {
      console.warn("⚠️ SaleCancelled skipped: invalid saleId");
      return;
    }

    const saleIdStr = saleId.toString();
    const cancelledByAddr = normalize(cancelledBy);

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 🧾 STATE UPDATE (idempotent)
    // ===============================
    await client.query(
      `
      UPDATE launchpad_sales
      SET status='CANCELLED'
      WHERE sale_id=$1
        AND status IS DISTINCT FROM 'CANCELLED'
      `,
      [saleIdStr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "LAUNCHPAD_CANCEL",
      null,
      saleIdStr,
      cancelledByAddr,
      cancelledByAddr,
      "0",
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

    if (cancelledByAddr) {
      pipe.del(`user:portfolio:${cancelledByAddr}`);
    }

    await pipe.exec();

    console.log("❌ Launchpad sale cancelled:", saleIdStr);

  } catch (err) {
    console.error("❌ handleSaleCancelled:", {
      saleId: args?.saleId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}