import { eventBus } from "../../utils/eventBus";
import { storeActivity } from "../activity/activity";
import {
  normalizeAddress,
  normalizePrice,
  normalizeTokenId,
} from "../normalize";

import type { EventContext } from "../types";

type Listed1155Args = {
  listingId: bigint;
  nft: string;
  tokenId: bigint;
  seller: string;
  quantity: bigint;
  pricePerUnit: bigint;
  paymentToken: string;
};

export async function handleListed1155(
  ctx: EventContext<Listed1155Args>
) {
  const { args, meta, client } = ctx;

  const contract = normalizeAddress(args.nft)!;
  const tokenId = normalizeTokenId(args.tokenId)!;
  const seller = normalizeAddress(args.seller)!;
  const price = normalizePrice(args.pricePerUnit)!;

  await client.query(
    `
      INSERT INTO listings
      (
        contract_address,
        token_id,
        seller,
        price,
        status
      )
      VALUES ($1,$2,$3,$4,'ACTIVE')
      ON CONFLICT (contract_address, token_id)
      DO UPDATE
      SET
        seller = EXCLUDED.seller,
        price = EXCLUDED.price,
        status = 'ACTIVE'
    `,
    [
      contract,
      tokenId,
      seller,
      price,
    ]
  );

  await storeActivity(
    "LIST",
    contract,
    tokenId,
    seller,
    seller,
    price,
    meta.transactionHash,
    meta.blockNumber,
    meta.logIndex,
    client
  );

  eventBus.emit("listing:created", {
    contract,
    tokenId,
    seller,
    price,
    quantity: args.quantity.toString(),
    listingId: args.listingId.toString(),
  });
}