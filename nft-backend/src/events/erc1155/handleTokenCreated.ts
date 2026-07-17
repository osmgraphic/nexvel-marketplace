import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleERC1155TokenCreated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ TokenCreated skipped: missing args/meta");
      return;
    }

    const { tokenId, maxSupply, uri } = args;

    if (tokenId === undefined) {
      console.warn("⚠️ TokenCreated skipped: invalid tokenId");
      return;
    }

    const contract = normalize(meta.address)!;
    const tokenIdStr = tokenId.toString();
    const maxSupplyStr = maxSupply ? maxSupply.toString() : null;
    const tokenURI = uri || "";

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 🪙 TOKEN UPSERT (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO tokens (contract_address, token_id, uri, max_supply)
      VALUES ($1,$2,$3,$4)
      ON CONFLICT (contract_address, token_id)
      DO UPDATE SET
        uri = EXCLUDED.uri,
        max_supply = EXCLUDED.max_supply
      WHERE tokens.uri IS DISTINCT FROM EXCLUDED.uri
         OR tokens.max_supply IS DISTINCT FROM EXCLUDED.max_supply
      `,
      [contract, tokenIdStr, tokenURI, maxSupplyStr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "TOKEN_CREATED",
      contract,
      tokenIdStr,
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

    pipe.del(`nft:${contract}:${tokenIdStr}`);
    pipe.del(`nft:full:${contract}:${tokenIdStr}`);
    pipe.del(`collection:full:${contract}`);

    await pipe.exec();

  } catch (err) {
    console.error("❌ ERC1155 TokenCreated error:", {
      contract: meta?.address,
      tokenId: args?.tokenId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}