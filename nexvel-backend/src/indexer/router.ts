import { decodeLog } from "../utils/decode";

// Marketplace
import { handleListingCreated } from "../events/marketplace/handleListingCreated";
import { handleListingCancelled } from "../events/marketplace/handleListingCancelled";
import { handleSale } from "../events/marketplace/handleSale";
import { handlePriceUpdated } from "../events/marketplace/handlePriceUpdated";
import { handleBidPlaced } from "../events/marketplace/handleBidPlaced";
import { handleAuctionCreated } from "../events/marketplace/handleAuctionCreated";
import { handleAuctionSettled } from "../events/marketplace/handleAuctionSettled";

// Launchpad
import { handleSaleCreated } from "../events/launchpad/handleSaleCreated";
import { handlePurchased } from "../events/launchpad/handlePurchased";
import { handleRefunded } from "../events/launchpad/handleRefunded";
import { handleSaleFinalized } from "../events/launchpad/handleSaleFinalized";
import { handleSaleCancelled as handleLaunchpadCancelled } from "../events/launchpad/handleSaleCancelled";
import { handleNFTClaimed } from "../events/launchpad/handleNFTClaimed";
import { handleFundsClaimed } from "../events/launchpad/handleFundsClaimed";

// Factory
import { handleCollectionCreated } from "../events/factory/handleCollectionCreated";
import { handleRegistryUpdated } from "../events/factory/handleRegistryUpdated";
import { handleImplementationsUpdated } from "../events/factory/handleImplementationsUpdated";

// Transfers
import { handleERC721Transfer } from "../events/erc721/handleTransfer";
import { handleERC1155TransferSingle } from "../events/erc1155/handleTransferSingle";
import { handleTransferBatch } from "../events/erc1155/handleTransferBatch";

const HANDLERS: Record<string, Function> = {
  ListingCreated: handleListingCreated,
  ListingCancelled: handleListingCancelled,
  PriceUpdated: handlePriceUpdated,
  Purchased: handleSale,
  BidPlaced: handleBidPlaced,
  AuctionCreated: handleAuctionCreated,
  AuctionSettled: handleAuctionSettled,

  SaleCreated: handleSaleCreated,
  PurchasedLaunchpad: handlePurchased,
  Refunded: handleRefunded,
  SaleFinalized: handleSaleFinalized,
  SaleCancelled: handleLaunchpadCancelled,
  NFTClaimed: handleNFTClaimed,
  FundsClaimed: handleFundsClaimed,

  CollectionCreated: handleCollectionCreated,
  RegistryUpdated: handleRegistryUpdated,
  ImplementationsUpdated: handleImplementationsUpdated,

  Transfer: handleERC721Transfer,
  TransferSingle: handleERC1155TransferSingle,
  TransferBatch: handleTransferBatch,
};

export async function routeLogs(logs: any[], dbClient: any) {
  const jobs: Promise<any>[] = [];

  for (const log of logs) {
    try {
      const decoded = decodeLog(log);
      if (!decoded) continue;

      const handler = HANDLERS[decoded.eventName];
      if (!handler) continue;

      jobs.push(
        handler(decoded.args, {
          transactionHash: log.transactionHash,
          blockNumber: Number(log.blockNumber),
          logIndex: log.logIndex,
          address: log.address,
        }, dbClient) // ✅ pass db client
      );

    } catch (err) {
      console.error("❌ Router error:", err);
    }
  }

  await Promise.allSettled(jobs);
}