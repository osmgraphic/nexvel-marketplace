import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { createNotification } from "../../api/notifications/notification.service";
import { notifyUser } from "../../socket/broadcaster";
import { eventBus } from "../../utils/eventBus";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleAuctionSettled(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ AuctionSettled skipped: missing args/meta");
      return;
    }

    const { nft, tokenId, winner, price } = args;

    if (!nft || tokenId === undefined || !winner) {
      console.warn("⚠️ AuctionSettled skipped: invalid data");
      return;
    }

    const contract = normalize(nft)!;
    const winnerAddr = normalize(winner)!;
    const tokenIdStr = tokenId.toString();
    const priceStr = price?.toString() || "0";

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 🏷️ AUCTION UPDATE (idempotent)
    // ===============================
    await client.query(
      `
      UPDATE auctions
      SET status='SETTLED'
      WHERE contract_address=$1 AND token_id=$2
        AND status IS DISTINCT FROM 'SETTLED'
      `,
      [contract, tokenIdStr]
    );

    // ===============================
    // 👤 OWNERSHIP UPDATE (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO owners (contract_address, token_id, owner_address)
      VALUES ($1,$2,$3)
      ON CONFLICT (contract_address, token_id)
      DO UPDATE SET owner_address = EXCLUDED.owner_address
      WHERE owners.owner_address IS DISTINCT FROM EXCLUDED.owner_address
      `,
      [contract, tokenIdStr, winnerAddr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "AUCTION_SETTLE",
      contract,
      tokenIdStr,
      null,
      winnerAddr,
      priceStr,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🔔 NOTIFICATION (winner)
    // ===============================
    await createNotification(
      winnerAddr,
      "AUCTION_SETTLE",
      "You won the auction 🎉",
      { contract, tokenId: tokenIdStr, price: priceStr },
      txHash
    );

    notifyUser(winnerAddr, {
      type: "AUCTION_SETTLE",
      contract,
      tokenId: tokenIdStr,
      price: priceStr,
    });

    // ===============================
    // 🧹 Event
    // ===============================
    eventBus.emit("auction:settled", {
      contract,
      tokenId,
      winner,
      price,
    });

    console.log("🏁 Auction settled:", contract, tokenIdStr);

  } catch (err) {
    console.error("❌ handleAuctionSettled:", {
      contract: args?.nft,
      tokenId: args?.tokenId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}