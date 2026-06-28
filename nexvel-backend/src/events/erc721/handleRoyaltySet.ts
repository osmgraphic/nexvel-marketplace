import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleERC721RoyaltySet(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // 🔥 guards
    if (!args || !meta) {
      console.warn("⚠️ RoyaltySet skipped: missing args/meta");
      return;
    }

    const { tokenId, receiver, royaltyBps } = args;

    if (!tokenId || !receiver) {
      console.warn("⚠️ RoyaltySet skipped: invalid data");
      return;
    }

    const contract = normalize(meta.address)!;
    const receiverAddr = normalize(receiver)!;
    const tokenIdStr = tokenId.toString();

    const txHash = meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 💰 ROYALTY UPDATE (idempotent)
    // ===============================
    const result = await client.query(
      `
      UPDATE tokens
      SET royalty_receiver = $1,
          royalty_bps = $2
      WHERE contract_address = $3
        AND token_id = $4
        AND (
          royalty_receiver IS DISTINCT FROM $1
          OR royalty_bps IS DISTINCT FROM $2
        )
      RETURNING token_id
      `,
      [receiverAddr, royaltyBps, contract, tokenIdStr]
    );

    // 🔥 skip if no change
    if (result.rowCount === 0) return;

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "ROYALTY_SET",
      contract,
      tokenIdStr,
      null,
      receiverAddr,
      royaltyBps?.toString() || null,
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
    console.error("❌ RoyaltySet error:", {
      contract: meta?.address,
      tokenId: args?.tokenId,
      err
    });

    throw err; // 🔥 important for upstream rollback
  }
}