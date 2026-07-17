import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";
import { PoolClient } from "pg";

function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handlePurchase1155(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    if (!args || !meta) return;

    const { listingId, buyer, quantity, totalPrice } = args;

    const buyerAddr = normalize(buyer)!;
    const qty = quantity;

    const res = await client.query(
      `
      UPDATE listings_1155
      SET quantity = quantity - $1
      WHERE listing_id=$2 AND quantity >= $1
      RETURNING contract_address, token_id
      `,
      [qty, listingId]
    );

    if (res.rowCount === 0) {
      console.warn("⚠️ Purchase1155 skipped (insufficient qty)");
      return;
    }

    await client.query(
      `DELETE FROM listings_1155 WHERE listing_id=$1 AND quantity<=0`,
      [listingId]
    );

    const { contract_address, token_id } = res.rows[0];

    await storeActivity(
      "BUY_1155",
      contract_address,
      token_id,
      null,
      buyerAddr,
      totalPrice.toString(),
      meta.transactionHash,
      meta.blockNumber,
      meta.logIndex,
      client
    );

    const pipe = redis.pipeline();
    pipe.del("listings:active");
    pipe.del(`nft:${contract_address}:${token_id}`);
    await pipe.exec();

  } catch (err) {
    console.error("❌ handlePurchase1155:", err);
    throw err;
  }
}