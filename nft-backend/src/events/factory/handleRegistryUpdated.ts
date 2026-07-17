import { PoolClient } from "pg";
import { redis } from "../../utils/redis";
import { storeActivity } from "../activity/activity";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleRegistryUpdated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ RegistryUpdated skipped: missing args/meta");
      return;
    }

    const { newRegistry } = args;

    if (!newRegistry) {
      console.warn("⚠️ RegistryUpdated skipped: invalid data");
      return;
    }

    const registryAddr = normalize(newRegistry)!;

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // ⚙️ CONFIG UPSERT (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO factory_config (key, value)
      VALUES ('registry', $1)
      ON CONFLICT (key)
      DO UPDATE SET value = EXCLUDED.value
      WHERE factory_config.value IS DISTINCT FROM EXCLUDED.value
      `,
      [registryAddr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "FACTORY_REGISTRY_UPDATE",
      null,
      "0",
      null,
      null,
      registryAddr,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🧹 CACHE INVALIDATION
    // ===============================
    const pipe = redis.pipeline();

    pipe.del("factory:config");
    pipe.del("factory:latest");

    await pipe.exec();

    console.log("🔧 Registry updated:", registryAddr);

  } catch (err) {
    console.error("❌ handleRegistryUpdated error:", {
      registry: args?.newRegistry,
      err
    });

    throw err; // 🔥 required for rollback
  }
}