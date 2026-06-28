import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleRefunded(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ Refunded skipped: missing args/meta");
      return;
    }

    const { saleId, buyer, amount } = args;

    if (!saleId || !buyer || !amount) {
      console.warn("⚠️ Refunded skipped: invalid data");
      return;
    }

    const saleIdStr = saleId.toString();
    const buyerAddr = normalize(buyer)!;
    const amountStr = amount.toString();

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 💸 REFUND HISTORY (idempotent)
    // ===============================
    const result = await client.query(
      `
      INSERT INTO launchpad_refunds
      (sale_id, buyer, amount, tx_hash)
      VALUES ($1,$2,$3,$4)
      ON CONFLICT (sale_id, buyer, tx_hash)
      DO NOTHING
      RETURNING sale_id
      `,
      [saleIdStr, buyerAddr, amountStr, txHash]
    );

    // 🔥 IMPORTANT: only update state if insert happened
    const isNew = (result.rowCount ?? 0) > 0;

    // ===============================
    // 📊 STATE CORRECTION (important)
    // ===============================
    if (isNew) {
      await client.query(
        `
        UPDATE launchpad_sales
        SET total_raised = total_raised - $1
        WHERE sale_id = $2
        `,
        [amountStr, saleIdStr]
      );
    }

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "LAUNCHPAD_REFUND",
      null,
      saleIdStr,
      buyerAddr,
      buyerAddr,
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
    pipe.del(`user:portfolio:${buyerAddr}`);

    await pipe.exec();

    console.log("↩️ Refund processed:", saleIdStr, buyerAddr);

  } catch (err) {
    console.error("❌ handleRefunded:", {
      saleId: args?.saleId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}