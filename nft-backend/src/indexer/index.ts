import { client } from "../blockchain/client";
import { pool } from "../database/db";
import { routeLogs } from "./router";
import { processBlock } from "./processor";
import { env } from "../config/env";
import { sleep } from "../utils/sleep";
import { initEnvironment } from "../bootstrap/environment";
import { initDatabase } from "../bootstrap/database";
import { initBlockchain } from "../bootstrap/blockchain";
import { initRegistry } from "../bootstrap/registry";
import { initContracts } from "../bootstrap/contracts";
import { initInterfaces } from "../bootstrap/interfaces";

import {
  initIndexerState,
  getLastProcessedBlock,
  updateLastProcessedBlock,
  saveBlock,
  isReorg,
  rollbackFromBlock,
} from "../blockchain/blocks";

// ===============================
const CONFIRMATIONS = env.INDEXER_CONFIRMATIONS;
// ===============================


// ===============================
// 🚀 MAIN LOOP
// ===============================

async function main() {
  console.log("🚀 Nexvel Indexer Started");

  await initEnvironment();
  await initDatabase();
  await initBlockchain();
  await initRegistry();
  await initContracts();
  await initInterfaces();

  await initIndexerState();

  let currentBlock = await getLastProcessedBlock();

  while (true) {
    try {
      const latest = await client.getBlockNumber();
      const latestNumber = Number(latest);

      const safeBlock = latestNumber - CONFIRMATIONS;

      if (currentBlock >= safeBlock) {
        await sleep(env.INDEXER_POLL_INTERVAL);
        continue;
      }

      while (currentBlock < safeBlock) {
        currentBlock++;
      
        // Process logs
        await processBlock(currentBlock);
      
        // Fetch block for checkpoint
        const block = await client.getBlock({
          blockNumber: BigInt(currentBlock),
        });
      
        // Save block history
        await saveBlock(
          currentBlock,
          block.hash,
          block.parentHash
        );
      
        // Save progress
        await updateLastProcessedBlock(currentBlock);
      
        // Prevent RPC rate limiting
        await sleep(100);
      }

    } catch (err) {
      console.error("❌ Indexer error:", err);
      await new Promise((res) => setTimeout(res, 3000));
    }
  }
}

main().catch(console.error);