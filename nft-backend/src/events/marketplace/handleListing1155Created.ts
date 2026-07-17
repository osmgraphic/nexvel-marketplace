import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";

export async function handleListing1155Created(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    const { listingId, nft, tokenId, seller, quantity, pricePerUnit } = args;

    const contract = nft.toLowerCase();
    const tokenIdStr = tokenId.toString();
    const sellerAddr = seller.toLowerCase();

    // ✅ Idempotent insert
    await client.query(
      `
      INSERT INTO listings_1155
      (listing_id, contract_address, token_id, seller, quantity, price_per_unit, status)
      VALUES ($1,$2,$3,$4,$5,$6,'ACTIVE')
      ON CONFLICT (listing_id)
      DO UPDATE SET
        quantity = EXCLUDED.quantity,
        price_per_unit = EXCLUDED.price_per_unit,
        status = 'ACTIVE'
      WHERE listings_1155.quantity IS DISTINCT FROM EXCLUDED.quantity
         OR listings_1155.price_per_unit IS DISTINCT FROM EXCLUDED.price_per_unit
         OR listings_1155.status IS DISTINCT FROM 'ACTIVE'
      `,
      [
        listingId,
        contract,
        tokenIdStr,
        sellerAddr,
        quantity,
        pricePerUnit.toString(),
      ]
    );

    // ✅ Activity
    await storeActivity(
      "LIST_1155",
      contract,
      tokenIdStr,
      sellerAddr,
      sellerAddr,
      pricePerUnit.toString(),
      meta.transactionHash,
      meta.blockNumber,
      meta.logIndex,
      client
    );

    // ✅ Redis pipeline (invalidate cache)
    const pipe = redis.pipeline();
    pipe.del("listings:active");
    pipe.del(`nft:${contract}:${tokenIdStr}`);
    pipe.del(`owner:${sellerAddr}`);
    await pipe.exec();

  } catch (err) {
    console.error("❌ handleListing1155Created error:", err);
    throw err;
  }
}