import { PoolClient } from "pg";
import { redis } from "../../utils/redis";
import { storeActivity } from "../activity/activity";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleNFTDeployed(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ NFTDeployed skipped: missing args/meta");
      return;
    }

    const { saleId, nft } = args;

    if (!saleId || !nft) {
      console.warn("⚠️ NFTDeployed skipped: invalid data");
      return;
    }

    const nftAddr = normalize(nft)!;
    const saleIdStr = saleId.toString();

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 🚀 UPDATE SALE (idempotent)
    // ===============================
    await client.query(
      `
      UPDATE launchpad_sales
      SET nft=$1
      WHERE sale_id=$2
        AND nft IS DISTINCT FROM $1
      `,
      [nftAddr, saleIdStr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "LAUNCHPAD_NFT_DEPLOYED",
      nftAddr,
      saleIdStr,
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

    pipe.del(`launchpad:sale:${saleIdStr}`);
    pipe.del("launchpad:active");
    pipe.del(`collection:full:${nftAddr}`);

    await pipe.exec();

    console.log("🚀 NFT deployed for sale:", saleIdStr, nftAddr);

  } catch (err) {
    console.error("❌ handleNFTDeployed:", {
      saleId: args?.saleId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}