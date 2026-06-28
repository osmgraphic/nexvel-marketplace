import { client as blockchainClient } from "../blockchain/client"; // ✅ rename
import { pool } from "../database/db";
import { routeLogs } from "./router";
import { CONTRACTS } from "../config/Contracts.Config";
import { isAddress } from "ethers";

const CONTRACT_ADDRESSES = CONTRACTS
  .map((c) => c.address)
  .filter((addr): addr is `0x${string}` => {
    return typeof addr === "string" && addr.startsWith("0x") && isAddress(addr);
  });

export async function processBlock(blockNumber: number) {
  console.log(`📦 Processing block ${blockNumber}`);

  const dbClient = await pool.connect(); // ✅ DB client

  try {
    // ✅ blockchain client used here
    const logs = await blockchainClient.getLogs({
      fromBlock: BigInt(blockNumber),
      toBlock: BigInt(blockNumber),
      address: CONTRACT_ADDRESSES,
    });

    if (logs.length === 0) return;

    // ✅ pass DB client forward
    await routeLogs(logs, dbClient);

  } catch (err) {
    console.error("❌ Error processing block:", blockNumber, err);
    throw err;
  } finally {
    dbClient.release();
  }
}