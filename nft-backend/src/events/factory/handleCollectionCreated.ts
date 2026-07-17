import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";
import { eventBus } from "../../utils/eventBus";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleCollectionCreated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ CollectionCreated skipped: missing args/meta");
      return;
    }

    const {
      creator,
      collection,
      implementation,
      nftType,
      name,
      symbol,
      maxSupply,
    } = args;

    if (!collection || !creator) {
      console.warn("⚠️ CollectionCreated skipped: invalid data");
      return;
    }

    const contract = normalize(collection)!;
    const creatorAddr = normalize(creator)!;
    const impl = normalize(implementation) || null;

    const txHash = meta.txHash || meta.transactionHash;
    const logIndex = meta.logIndex;
    const blockNumber = Number(meta.blockNumber);

    const maxSupplyStr = maxSupply ? maxSupply.toString() : null;

    // ===============================
    // 🏭 FACTORY HISTORY (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO factory_creations
      (creator, nft_contract, implementation, nft_type, name, symbol, max_supply, tx_hash, log_index, block_number)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
      ON CONFLICT (tx_hash, log_index) DO NOTHING
      `,
      [
        creatorAddr,
        contract,
        impl,
        nftType,
        name,
        symbol,
        maxSupplyStr,
        txHash,
        logIndex,
        blockNumber,
      ]
    );

    // ===============================
    // 📦 COLLECTION STATE (idempotent upsert)
    // ===============================
    await client.query(
      `
      INSERT INTO collections
      (contract_address, name, symbol, creator, factory_created, created_at)
      VALUES ($1,$2,$3,$4,true,NOW())
      ON CONFLICT (contract_address)
      DO UPDATE SET
        name = EXCLUDED.name,
        symbol = EXCLUDED.symbol
      WHERE collections.name IS DISTINCT FROM EXCLUDED.name
         OR collections.symbol IS DISTINCT FROM EXCLUDED.symbol
      `,
      [contract, name, symbol, creatorAddr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "COLLECTION_CREATED",
      contract,
      "0",
      creatorAddr,
      creatorAddr,
      "0",
      txHash,
      blockNumber,
      logIndex,
      client
    );

    eventBus.emit("collection:created", {
      contract,
      creator: creatorAddr,
      name,
      symbol,
      nftType,
      implementation: impl,
      maxSupply: maxSupplyStr,
      txHash,
      blockNumber,
    });

    console.log("🏭 Collection indexed:", contract);

  } catch (err) {
    console.error("❌ handleCollectionCreated error:", {
      contract: args?.collection,
      err
    });

    throw err; // 🔥 required for rollback
  }
}