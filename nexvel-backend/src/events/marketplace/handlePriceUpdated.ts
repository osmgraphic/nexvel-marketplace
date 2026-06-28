import { storeActivity } from "../activity/activity";
import { PoolClient } from "pg";
import { eventBus } from "../../utils/eventBus";

function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handlePriceUpdated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    if (!args || !meta) return;

    const { nft, tokenId, newPrice } = args;

    const contract = normalize(nft)!;
    const tokenIdStr = tokenId.toString();
    const priceStr = newPrice.toString();

    await client.query(
      `
      UPDATE listings
      SET price=$1
      WHERE contract_address=$2
        AND token_id=$3
        AND price IS DISTINCT FROM $1
      `,
      [priceStr, contract, tokenIdStr]
    );

    await storeActivity(
      "PRICE_UPDATE",
      contract,
      tokenIdStr,
      null,
      null,
      priceStr,
      meta.transactionHash,
      meta.blockNumber,
      meta.logIndex,
      client
    );

    eventBus.emit("listing:price:update", {
      contract,
      tokenId: tokenIdStr,
      price: newPrice,
    });

  } catch (err) {
    console.error("❌ handlePriceUpdated:", err);
    throw err;
  }
}