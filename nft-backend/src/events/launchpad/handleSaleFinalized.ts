import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { eventBus } from "../../utils/eventBus";

// 🔧 helpers
function toStr(v: any) {
  return v !== undefined && v !== null ? v.toString() : null;
}

export async function handleSaleFinalized(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ SaleFinalized skipped: missing args/meta");
      return;
    }

    const { saleId, status, totalRaised } = args;

    if (!saleId || !status) {
      console.warn("⚠️ SaleFinalized skipped: invalid data");
      return;
    }

    const saleIdStr = saleId.toString();
    const totalRaisedStr = toStr(totalRaised);

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 🧾 STATE UPDATE (idempotent)
    // ===============================
    await client.query(
      `
      UPDATE launchpad_sales
      SET status = $1,
          total_raised = $2
      WHERE sale_id = $3
        AND (
          status IS DISTINCT FROM $1 OR
          total_raised IS DISTINCT FROM $2
        )
      `,
      [status, totalRaisedStr, saleIdStr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "LAUNCHPAD_FINALIZE",
      null,
      saleIdStr,
      null,
      null,
      totalRaisedStr,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🧹 Event
    // ===============================
    eventBus.emit("launchpad:finalize", {
      saleId,
      status,
    });

    console.log("🏁 Launchpad sale finalized:", saleIdStr, status);

  } catch (err) {
    console.error("❌ handleSaleFinalized:", {
      saleId: args?.saleId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}