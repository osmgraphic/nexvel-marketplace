import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";
import { createNotification } from "../../api/notifications/notification.service";
import { notifyUser } from "../../utils/socket";
import { eventBus } from "../../utils/eventBus";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleAuctionCreated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ AuctionCreated skipped: missing args/meta");
      return;
    }

    const { seller, nft, tokenId, startPrice, endTime } = args;

    if (!seller || !nft || tokenId === undefined) {
      console.warn("⚠️ AuctionCreated skipped: invalid data");
      return;
    }

    const contract = normalize(nft)!;
    const sellerAddr = normalize(seller)!;
    const tokenIdStr = tokenId.toString();
    const priceStr = startPrice?.toString() || "0";

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    const endTimeDate = endTime
      ? new Date(Number(endTime) * 1000)
      : null;

    // ===============================
    // 🏷️ AUCTION UPSERT (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO auctions
      (contract_address, token_id, seller, start_price, end_time, status)
      VALUES ($1,$2,$3,$4,$5,'ACTIVE')
      ON CONFLICT (contract_address, token_id)
      DO UPDATE SET
        seller = EXCLUDED.seller,
        start_price = EXCLUDED.start_price,
        end_time = EXCLUDED.end_time,
        status = 'ACTIVE'
      WHERE auctions.start_price IS DISTINCT FROM EXCLUDED.start_price
         OR auctions.end_time IS DISTINCT FROM EXCLUDED.end_time
         OR auctions.status IS DISTINCT FROM 'ACTIVE'
      `,
      [
        contract,
        tokenIdStr,
        sellerAddr,
        priceStr,
        endTimeDate,
      ]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "AUCTION_CREATE",
      contract,
      tokenIdStr,
      sellerAddr,
      sellerAddr,
      priceStr,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🔔 NOTIFICATION (seller)
    // ===============================
    await createNotification(
      sellerAddr,
      "AUCTION_CREATE",
      "Your auction is live",
      { contract, tokenId: tokenIdStr, price: priceStr },
      txHash
    );

    notifyUser(sellerAddr, {
      type: "AUCTION_CREATE",
      contract,
      tokenId: tokenIdStr,
    });

    // ===============================
    // 🔔 Event
    // ===============================

    eventBus.emit("auction:created", {
      contract,
      tokenId,
      seller,
      startPrice,
    });

    console.log("🏷️ Auction created:", contract, tokenIdStr);

  } catch (err) {
    console.error("❌ handleAuctionCreated:", {
      contract: args?.nft,
      tokenId: args?.tokenId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}