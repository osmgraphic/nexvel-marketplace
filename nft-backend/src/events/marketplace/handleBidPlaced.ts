import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { createNotification } from "../../api/notifications/notification.service";
import { notifyUser } from "../../socket/broadcaster";
import { eventBus } from "../../utils/eventBus";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleBidPlaced(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ BidPlaced skipped: missing args/meta");
      return;
    }

    const { bidder, nft, tokenId, amount } = args;

    if (!bidder || !nft || tokenId === undefined || !amount) {
      console.warn("⚠️ BidPlaced skipped: invalid data");
      return;
    }

    const contract = normalize(nft)!;
    const bidderAddr = normalize(bidder)!;

    const tokenIdStr = tokenId.toString();
    const amountStr = amount.toString();

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 💸 BID INSERT (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO bids
      (contract_address, token_id, bidder, amount, tx_hash, log_index)
      VALUES ($1,$2,$3,$4,$5,$6)
      ON CONFLICT (tx_hash, log_index) DO NOTHING
      `,
      [
        contract,
        tokenIdStr,
        bidderAddr,
        amountStr,
        txHash,
        logIndex
      ]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "BID",
      contract,
      tokenIdStr,
      bidderAddr,
      null,
      amountStr,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🔔 NOTIFICATION (bidder)
    // ===============================
    await createNotification(
      bidderAddr,
      "BID",
      "Your bid has been placed",
      { contract, tokenId: tokenIdStr, amount: amountStr },
      txHash
    );

    notifyUser(bidderAddr, {
      type: "BID",
      contract,
      tokenId: tokenIdStr,
      amount: amountStr,
    });

    // ===============================
    // 🧹 Event
    // ===============================
    eventBus.emit("auction:bid", {
      contract,
      tokenId,
      bidder,
      amount,
    });

    console.log("💸 Bid placed:", contract, tokenIdStr, amountStr);

  } catch (err) {
    console.error("❌ handleBidPlaced:", {
      contract: args?.nft,
      tokenId: args?.tokenId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}