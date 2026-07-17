import { storeActivity } from "../activity/activity";
import { PoolClient } from "pg";
import { eventBus } from "../../utils/eventBus";
import type { EventMeta } from "../types";
import {
  normalizeAddress,
  normalizePrice,
  normalizeTokenId,
} from "../normalize";
import type { EventContext } from "../types";

type ListingCreatedArgs = {
  listingId: bigint;
  nft: string;
  tokenId: bigint;
  seller: string;
  quantity: bigint;
  pricePerUnit: bigint;
  paymentToken: string;
};

export async function handleListingCreated(
  ctx: EventContext<ListingCreatedArgs>
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
  });
}