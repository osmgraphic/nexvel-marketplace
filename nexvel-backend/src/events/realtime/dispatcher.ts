import { eventBus } from "../../utils/eventBus";
import {
  invalidateNFT,
  invalidateUser,
  invalidateListings
} from "../../utils/cacheInvalidation";

import {
  broadcast,
  broadcastToCollection,
  broadcastToUser
} from "../../utils/socket";

// 🔥 LISTING CREATED
eventBus.on("listing:created", async (data) => {
  const { contract, tokenId, seller, price } = data;

  await invalidateNFT(contract, tokenId);
  await invalidateUser(seller);
  await invalidateListings();

  broadcast("listing:new", data);
  broadcastToCollection(contract, "collection:update", data);
});

// 🔥 SALE
eventBus.on("sale", async (data) => {
  const { contract, tokenId, buyer, seller, price } = data;

  await invalidateNFT(contract, tokenId);
  await invalidateUser(buyer);
  await invalidateUser(seller);
  await invalidateListings();

  broadcast("sale:new", data);
  broadcastToUser(buyer, "user:purchase", data);
  broadcastToCollection(contract, "collection:sale", data);
});

// 🔥 TRANSFER
eventBus.on("transfer", async (data) => {
  const { contract, tokenId, from, to } = data;

  await invalidateNFT(contract, tokenId);
  await invalidateUser(from);
  await invalidateUser(to);

  broadcastToCollection(contract, "collection:transfer", data);
});