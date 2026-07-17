import { PoolClient } from "pg";
import { redis } from "../../utils/redis";
import { storeActivity } from "../activity/activity";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleImplementationsUpdated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ ImplementationsUpdated skipped: missing args/meta");
      return;
    }

    const { erc721Impl, erc721AImpl } = args;

    if (!erc721Impl || !erc721AImpl) {
      console.warn("⚠️ ImplementationsUpdated skipped: invalid data");
      return;
    }

    const erc721 = normalize(erc721Impl)!;
    const erc721A = normalize(erc721AImpl)!;

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // ⚙️ CONFIG UPSERT (idempotent)
    // ===============================

    // ERC721
    await client.query(
      `
      INSERT INTO factory_config (key, value)
      VALUES ('erc721_impl', $1)
      ON CONFLICT (key)
      DO UPDATE SET value = EXCLUDED.value
      WHERE factory_config.value IS DISTINCT FROM EXCLUDED.value
      `,
      [erc721]
    );

    // ERC721A
    await client.query(
      `
      INSERT INTO factory_config (key, value)
      VALUES ('erc721A_impl', $1)
      ON CONFLICT (key)
      DO UPDATE SET value = EXCLUDED.value
      WHERE factory_config.value IS DISTINCT FROM EXCLUDED.value
      `,
      [erc721A]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "FACTORY_IMPLEMENTATION_UPDATE",
      null,
      "0",
      null,
      null,
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

    pipe.del("factory:config");
    pipe.del("factory:latest");

    await pipe.exec();

    console.log("⚙️ Implementations updated");

  } catch (err) {
    console.error("❌ handleImplementationsUpdated error:", {
      erc721: args?.erc721Impl,
      erc721A: args?.erc721AImpl,
      err
    });

    throw err; // 🔥 important for rollback
  }
}