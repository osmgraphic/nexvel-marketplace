import { PoolClient } from "pg";
import { handlePurchased } from "./handlePurchased";

// ✍️ Signature-based purchase
export async function handleSignaturePurchased(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ SignaturePurchased skipped: missing args/meta");
      return;
    }

    if (!args.saleId || !args.buyer) {
      console.warn("⚠️ SignaturePurchased skipped: invalid data");
      return;
    }

    // ===============================
    // 🚀 FORWARD WITH TYPE
    // ===============================
    await handlePurchased(
      {
        ...args,
        purchaseType: "SIGNATURE", // 👈 KEY
      },
      meta,
      client
    );

    console.log("🖊️ Signature purchase:", args.saleId);

  } catch (err) {
    console.error("❌ handleSignaturePurchased:", err);
    throw err;
  }
}