import { storeActivity } from "../activity/activity";
import { PoolClient } from "pg";
import { eventBus } from "../../utils/eventBus";

export async function handleListingCreated(args: any, meta: any, client: PoolClient) {
  try {
    const { seller, nft, tokenId, price } = args;

    const contract = nft.toLowerCase();
    const tokenIdStr = tokenId.toString();
    const sellerAddr = seller.toLowerCase();

    await client.query(
      `
      INSERT INTO listings
      (contract_address, token_id, seller, price, status)
      VALUES ($1,$2,$3,$4,'ACTIVE')
      ON CONFLICT (contract_address, token_id)
      DO UPDATE SET price = EXCLUDED.price, status='ACTIVE'
      `,
      [contract, tokenIdStr, sellerAddr, price]
    );

    await storeActivity(
      "LIST",
      contract,
      tokenIdStr,
      sellerAddr,
      sellerAddr,
      price,
      meta.transactionHash,
      meta.blockNumber,
      meta.logIndex,
      client
    );

    // 🔥 EVENT
    eventBus.emit("listing:created", {
      contract,
      tokenId: tokenIdStr,
      seller: sellerAddr,
      price,
    });

  } catch (err) {
    throw err;
  }
}