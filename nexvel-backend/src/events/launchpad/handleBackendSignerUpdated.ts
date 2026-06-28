import { PoolClient } from "pg";
import { redis } from "../../utils/redis";
import { storeActivity } from "../activity/activity";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleBackendSignerUpdated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ BackendSignerUpdated skipped: missing args/meta");
      return;
    }

    const { oldSigner, newSigner } = args;

    if (!newSigner) {
      console.warn("⚠️ BackendSignerUpdated skipped: invalid data");
      return;
    }

    const newAddr = normalize(newSigner)!;
    const oldAddr = normalize(oldSigner);

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // ⚙️ CONFIG UPSERT (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO launchpad_config (key, value)
      VALUES ('backend_signer', $1)
      ON CONFLICT (key)
      DO UPDATE SET value = EXCLUDED.value
      WHERE launchpad_config.value IS DISTINCT FROM EXCLUDED.value
      `,
      [newAddr]
    );

    // ===============================
    // 📊 ACTIVITY (FIXED DIRECTION)
    // ===============================
    await storeActivity(
      "LAUNCHPAD_SIGNER_UPDATE",
      null,
      "0",
      oldAddr,   // ✅ from old
      newAddr,   // ✅ to new
      null,
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

    console.log("🔐 Backend signer updated:", newAddr);

  } catch (err) {
    console.error("❌ handleBackendSignerUpdated:", {
      newSigner: args?.newSigner,
      err
    });

    throw err; // 🔥 required for rollback
  }
}