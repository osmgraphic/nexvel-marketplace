import { PoolClient } from "pg";
import { redis } from "../../utils/redis";
import { storeActivity } from "../activity/activity";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handlePaymentTokenUpdated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ PaymentTokenUpdated skipped: missing args/meta");
      return;
    }

    const { token, allowed } = args;

    if (!token) {
      console.warn("⚠️ PaymentTokenUpdated skipped: invalid token");
      return;
    }

    const tokenAddr = normalize(token)!;
    const allowedStr = allowed ? "1" : "0";

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    // ===============================
    // 💳 TOKEN UPSERT (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO launchpad_payment_tokens (token_address, is_allowed)
      VALUES ($1,$2)
      ON CONFLICT (token_address)
      DO UPDATE SET is_allowed = EXCLUDED.is_allowed
      WHERE launchpad_payment_tokens.is_allowed IS DISTINCT FROM EXCLUDED.is_allowed
      `,
      [tokenAddr, allowed]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "LAUNCHPAD_TOKEN_UPDATE",
      null,
      "0",
      null,
      tokenAddr,
      allowedStr,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🧹 CACHE INVALIDATION
    // ===============================
    const pipe = redis.pipeline();

    pipe.del("launchpad:config");
    pipe.del("launchpad:payment_tokens");
    pipe.del("launchpad:active");

    await pipe.exec();

    console.log("💳 Payment token updated:", tokenAddr, allowed);

  } catch (err) {
    console.error("❌ handlePaymentTokenUpdated:", {
      token: args?.token,
      err
    });

    throw err; // 🔥 required for rollback
  }
}