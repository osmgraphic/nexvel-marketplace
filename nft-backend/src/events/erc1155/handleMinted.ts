import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";
import { PoolClient } from "pg";
import { createNotification } from "../../api/notifications/notification.service";
import { notifyUser } from "../../socket/broadcaster";

const ZERO = "0x0000000000000000000000000000000000000000";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleERC1155Minted(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ ERC1155 Mint skipped: missing args/meta");
      return;
    }

    const { to, tokenId, amount } = args;

    if (!to || tokenId === undefined || !amount) {
      console.warn("⚠️ ERC1155 Mint skipped: invalid data");
      return;
    }

    const contract = normalize(meta.address)!;
    const toAddr = normalize(to)!;
    const tokenIdStr = tokenId.toString();
    const amountStr = amount.toString();

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 📊 BALANCE UPSERT (idempotent add)
    // ===============================
    await client.query(
      `
      INSERT INTO token_balances (owner, contract_address, token_id, balance)
      VALUES ($1,$2,$3,$4)
      ON CONFLICT (owner, contract_address, token_id)
      DO UPDATE SET balance = token_balances.balance + EXCLUDED.balance
      `,
      [toAddr, contract, tokenIdStr, amountStr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "MINT",
      contract,
      tokenIdStr,
      ZERO,
      toAddr,
      "0",
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🔔 NOTIFICATION
    // ===============================
    await createNotification(
      toAddr,
      "MINT",
      "You received ERC1155 tokens",
      { contract, tokenId: tokenIdStr, amount: amountStr },
      txHash
    );

    notifyUser(toAddr, {
      type: "MINT",
      contract,
      tokenId: tokenIdStr,
      amount: amountStr,
    });

    // ===============================
    // 🧹 CACHE INVALIDATION
    // ===============================
    const pipe = redis.pipeline();

    pipe.del(`balance:${toAddr}`);
    pipe.del(`nft:${contract}:${tokenIdStr}`);
    pipe.del(`collection:full:${contract}`);

    await pipe.exec();

  } catch (err) {
    console.error("❌ ERC1155 Mint error:", {
      contract: meta?.address,
      tokenId: args?.tokenId,
      err
    });

    throw err; // 🔥 important for rollback
  }
}