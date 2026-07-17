import { storeActivity } from "../activity/activity";
import { PoolClient } from "pg";
import { eventBus } from "../../utils/eventBus";

export async function handleSale(args: any, meta: any, client: PoolClient) {
  try {
    const { buyer, seller, nft, tokenId, price } = args;

    const contract = nft.toLowerCase();
    const tokenIdStr = tokenId.toString();
    const buyerAddr = buyer.toLowerCase();
    const sellerAddr = seller.toLowerCase();

    await client.query(
      `
      INSERT INTO sales
      (contract_address, token_id, buyer, seller, price, tx_hash)
      VALUES ($1,$2,$3,$4,$5,$6)
      ON CONFLICT (tx_hash, token_id) DO NOTHING
      `,
      [contract, tokenIdStr, buyerAddr, sellerAddr, price, meta.transactionHash]
    );

    await storeActivity(
      "SALE",
      contract,
      tokenIdStr,
      sellerAddr,
      buyerAddr,
      price,
      meta.transactionHash,
      meta.blockNumber,
      meta.logIndex,
      client
    );

    // 🔥 EVENT
    eventBus.emit("sale", {
      contract,
      tokenId: tokenIdStr,
      buyer: buyerAddr,
      seller: sellerAddr,
      price,
    });

  } catch (err) {
    throw err;
  }
}