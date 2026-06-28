import { PoolClient } from "pg";
import { handleERC1155TransferSingle } from "./handleTransferSingle";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleTransferBatch(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ TransferBatch skipped: missing args/meta");
      return;
    }

    const { from, to, ids, values } = args;

    if (!Array.isArray(ids) || !Array.isArray(values)) {
      console.warn("⚠️ TransferBatch skipped: invalid arrays");
      return;
    }

    if (ids.length !== values.length) {
      console.warn("⚠️ TransferBatch skipped: mismatch ids/values");
      return;
    }

    const fromAddr = normalize(from);
    const toAddr = normalize(to);

    // ===============================
    // 🔁 PROCESS EACH TRANSFER
    // ===============================
    for (let i = 0; i < ids.length; i++) {
      await handleERC1155TransferSingle(
        {
          from: fromAddr,
          to: toAddr,
          tokenId: ids[i],   // ✅ FIXED
          amount: values[i], // ✅ FIXED
        },
        meta,
        client
      );
    }

  } catch (err) {
    console.error("❌ TransferBatch error:", {
      contract: meta?.address,
      err
    });

    throw err; // 🔥 important for rollback
  }
}