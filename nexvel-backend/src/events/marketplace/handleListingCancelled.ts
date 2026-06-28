import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";
import { PoolClient } from "pg";
import { eventBus } from "../../utils/eventBus";

export async function handleListingCancelled(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    const { nft, tokenId, seller } = args;

    const contract = nft.toLowerCase();
    const tokenIdStr = tokenId.toString();
    const sellerAddr = seller.toLowerCase();

    await client.query(
      `
      UPDATE listings
      SET status='CANCELLED'
      WHERE contract_address=$1
        AND token_id=$2
        AND status IS DISTINCT FROM 'CANCELLED'
      `,
      [contract, tokenIdStr]
    );

    await storeActivity(
      "CANCEL",
      contract,
      tokenIdStr,
      sellerAddr,
      sellerAddr,
      "0",
      meta.transactionHash,
      meta.blockNumber,
      meta.logIndex,
      client
    );

    eventBus.emit("listing:cancelled", {
      contract,
      tokenId: tokenIdStr,
      seller: sellerAddr,
    });

  } catch (err) {
    console.error("❌ handleListingCancelled:", err);
    throw err;
  }
}