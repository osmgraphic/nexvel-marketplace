import { pool } from "../../database/db";
import { PoolClient } from "pg";
import {
  normalizeAddress,
  normalizePrice,
  normalizeTokenId,
} from "../normalize";

// 🔧 helpers


export async function storeActivity(
  eventType: string,
  contract: string | null,
  tokenId: string | number | bigint | null,
  from: string | null,
  to: string | null,
  price: string | number | null,
  txHash: string,
  blockNumber: number,
  logIndex: number,
  client?: PoolClient
) {
  // 🔥 critical guard (idempotency safety)
  if (!txHash || logIndex === undefined || logIndex === null) {
    console.warn("⚠️ Skipping activity: missing txHash/logIndex");
    return;
  }

  // 🔥 normalize inputs
const contractAddr = normalizeAddress(contract);
const fromAddr = normalizeAddress(from);
const toAddr = normalizeAddress(to);

const tokenIdStr = normalizeTokenId(tokenId);
const priceStr = normalizePrice(price);

  // 🔥 choose client
  const dbClient = client ?? (await pool.connect());
  const shouldRelease = !client;

  try {
    await dbClient.query(
      `
      INSERT INTO activities
      (
        event_type,
        contract_address,
        token_id,
        from_address,
        to_address,
        price,
        tx_hash,
        block_number,
        log_index
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      ON CONFLICT (tx_hash, log_index) DO NOTHING
      `,
      [
        eventType,
        contractAddr,
        tokenIdStr,
        fromAddr,
        toAddr,
        priceStr,
        txHash,
        blockNumber,
        logIndex,
      ]
    );

  } catch (err) {
    console.error("❌ Activity store error:", {
      eventType,
      contract: contractAddr,
      tokenId: tokenIdStr,
      txHash,
      logIndex,
      err
    });

    throw err; // 🔥 ensures rollback upstream
  } finally {
    if (shouldRelease) {
      dbClient.release();
    }
  }
}