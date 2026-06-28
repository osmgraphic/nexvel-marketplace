import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { eventBus } from "../../utils/eventBus";

// 🔧 helpers
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handlePurchased(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ Purchased skipped: missing args/meta");
      return;
    }

    const {
      saleId,
      buyer,
      quantity,
      paymentToken,
      totalPaid,
      purchaseType, // 👈 NEW
    } = args;

    if (!saleId || !buyer || !quantity) {
      console.warn("⚠️ Purchased skipped: invalid data");
      return;
    }

    const saleIdStr = saleId.toString();
    const buyerAddr = normalize(buyer)!;
    const tokenAddr = normalize(paymentToken);
    const qty = Number(quantity);
    const paid = totalPaid?.toString() || "0";

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 🧾 PURCHASE HISTORY (idempotent)
    // ===============================
    const result = await client.query(
      `
      INSERT INTO launchpad_purchases
      (sale_id, buyer, quantity, total_paid, payment_token, tx_hash)
      VALUES ($1,$2,$3,$4,$5,$6)
      ON CONFLICT (sale_id, buyer, tx_hash)
      DO NOTHING
      RETURNING sale_id
      `,
      [
        saleIdStr,
        buyerAddr,
        qty,
        paid,
        tokenAddr,
        txHash,
      ]
    );

    // 🔥 IMPORTANT: only update state if insert happened
    const isNew = (result.rowCount ?? 0) > 0;

    // ===============================
    // 📊 UPDATE SALE STATE (SAFE)
    // ===============================
    if (isNew) {
      await client.query(
        `
        UPDATE launchpad_sales
        SET sold = sold + $1,
            total_raised = total_raised + $2
        WHERE sale_id = $3
        `,
        [qty, paid, saleIdStr]
      );
    }

    // ===============================
    // 📊 ACTIVITY TYPE (KEY PART)
    // ===============================
    const activityType =
      purchaseType === "SIGNATURE"
        ? "LAUNCHPAD_BUY_SIGNATURE"
        : "LAUNCHPAD_BUY";

    await storeActivity(
      activityType,
      null,
      saleIdStr,
      buyerAddr,
      buyerAddr,
      paid,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🧹 Event
    // ===============================
    eventBus.emit("launchpad:buy", {
      saleId,
      buyer,
      quantity,
      totalPaid,
    });

    console.log(`🛒 ${activityType}:`, saleIdStr, buyerAddr, qty);

  } catch (err) {
    console.error("❌ handlePurchased:", {
      saleId: args?.saleId,
      err
    });

    throw err;
  }
}