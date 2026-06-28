import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleERC721MetadataUpdated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // 🔥 guards
    if (!args || !meta) {
      console.warn("⚠️ Metadata update skipped: missing args/meta");
      return;
    }

    const { tokenId, newURI } = args;

    if (!tokenId || !newURI) {
      console.warn("⚠️ Metadata update skipped: invalid data");
      return;
    }

    const contract = normalize(meta.address);
    const tokenIdStr = tokenId.toString();
    const uri = newURI.trim();

    // 🔥 skip empty uri
    if (!uri) return;

    // ✅ update only if changed
    const result = await client.query(
      `
      UPDATE tokens
      SET uri = $1
      WHERE contract_address = $2
        AND token_id = $3
        AND uri IS DISTINCT FROM $1
      RETURNING token_id
      `,
      [uri, contract, tokenIdStr]
    );

    // 🔥 if nothing updated → skip
    if (result.rowCount === 0) return;

    // ✅ optional activity (useful for debugging / UI refresh triggers)
    await storeActivity(
      "METADATA_UPDATE",
      contract!,
      tokenIdStr,
      null,
      null,
      null,
      meta.transactionHash,
      Number(meta.blockNumber),
      meta.logIndex,
      client
    );

    // 🔥 cache invalidation
    const pipe = redis.pipeline();
    pipe.del(`nft:${contract}:${tokenIdStr}`);
    pipe.del(`nft:full:${contract}:${tokenIdStr}`);
    await pipe.exec();

  } catch (err) {
    console.error("❌ Metadata update error:", {
      contract: meta?.address,
      tokenId: args?.tokenId,
      err
    });

    throw err; // 🔥 important for rollback
  }
}