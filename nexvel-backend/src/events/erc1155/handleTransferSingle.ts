import { storeActivity } from "../activity/activity";
import { redis } from "../../utils/redis";
import { PoolClient } from "pg";
import { createNotification } from "../../api/notifications/notification.service";
import { notifyUser } from "../../utils/socket";

const ZERO = "0x0000000000000000000000000000000000000000";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleERC1155TransferSingle(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ ERC1155 Transfer skipped: missing args/meta");
      return;
    }

    const { from, to, tokenId, amount } = args;

    if (!from || !to || tokenId === undefined || !amount) {
      console.warn("⚠️ ERC1155 Transfer skipped: invalid data");
      return;
    }

    const contract = normalize(meta.address)!;
    const fromAddr = normalize(from)!;
    const toAddr = normalize(to)!;

    const tokenIdStr = tokenId.toString();
    const amountStr = amount.toString();

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 📉 DECREASE BALANCE (SAFE)
    // ===============================
    if (fromAddr !== ZERO) {
      const res = await client.query(
        `
        UPDATE token_balances
        SET balance = balance - $1
        WHERE owner=$2 AND contract_address=$3 AND token_id=$4
          AND balance >= $1
        RETURNING balance
        `,
        [amountStr, fromAddr, contract, tokenIdStr]
      );

      if (res.rowCount === 0) {
        console.warn("⚠️ Balance underflow prevented", {
          contract,
          tokenId: tokenIdStr,
          from: fromAddr
        });
      }
    }

    // ===============================
    // 📈 INCREASE BALANCE
    // ===============================
    if (toAddr !== ZERO) {
      await client.query(
        `
        INSERT INTO token_balances (owner, contract_address, token_id, balance)
        VALUES ($1,$2,$3,$4)
        ON CONFLICT (owner, contract_address, token_id)
        DO UPDATE SET balance = token_balances.balance + EXCLUDED.balance
        `,
        [toAddr, contract, tokenIdStr, amountStr]
      );
    }

    // ===============================
    // 📊 ACTIVITY TYPE
    // ===============================
    let activityType = "TRANSFER";
    if (fromAddr === ZERO) activityType = "MINT";
    if (toAddr === ZERO) activityType = "BURN";

    await storeActivity(
      activityType,
      contract,
      tokenIdStr,
      fromAddr,
      toAddr,
      amountStr,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🔔 NOTIFICATIONS
    // ===============================
    if (activityType === "TRANSFER") {
      await createNotification(
        toAddr,
        "TRANSFER",
        "Received ERC1155 tokens",
        { contract, tokenId: tokenIdStr, amount: amountStr },
        txHash
      );

      notifyUser(toAddr, {
        type: "TRANSFER",
        contract,
        tokenId: tokenIdStr,
        amount: amountStr,
      });
    }

    // ===============================
    // 🧹 CACHE INVALIDATION
    // ===============================
    const pipe = redis.pipeline();

    pipe.del(`balance:${fromAddr}`);
    pipe.del(`balance:${toAddr}`);
    pipe.del(`nft:${contract}:${tokenIdStr}`);
    pipe.del(`collection:full:${contract}`);

    await pipe.exec();

  } catch (err) {
    console.error("❌ ERC1155 Transfer error:", {
      contract: meta?.address,
      tokenId: args?.tokenId,
      err
    });

    throw err; // 🔥 critical for rollback
  }
}