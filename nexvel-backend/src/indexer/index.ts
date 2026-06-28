import { client } from "../blockchain/client";
import { pool } from "../database/db";
import { routeLogs } from "./router";

import {
  initIndexerState,
  getLastProcessedBlock,
  updateLastProcessedBlock,
  saveBlock,
  isReorg,
  rollbackFromBlock,
} from "../blockchain/blocks";

// ===============================
const CONFIRMATIONS = 5;
// ===============================

async function processBlock(blockNumber: number) {
  const dbClient = await pool.connect(); // 🔥 reuse per block

  try {
    const block = await client.getBlock({
      blockNumber: BigInt(blockNumber),
    });

    if (!block) return;

    const bn = Number(block.number);

    // ===============================
    // ⚠️ REORG DETECTION
    // ===============================
    const reorg = await isReorg(bn, block.hash);

    if (reorg) {
      await rollbackFromBlock(bn);
      return;
    }

    // ===============================
    // 📦 COLLECT LOGS
    // ===============================
    const logs: any[] = [];

    for (const txHash of block.transactions) {
      const receipt = await client.getTransactionReceipt({
        hash: txHash,
      });

      if (receipt?.logs?.length) {
        logs.push(...receipt.logs);
      }
    }

    if (logs.length === 0) {
      await saveBlock(bn, block.hash, block.parentHash);
      await updateLastProcessedBlock(bn);
      return;
    }

    // ===============================
    // 🚦 ROUTE EVENTS
    // ===============================
    await routeLogs(logs, dbClient);

    // ===============================
    // 💾 SAVE CHECKPOINT
    // ===============================
    await saveBlock(bn, block.hash, block.parentHash);
    await updateLastProcessedBlock(bn);

    console.log(`✅ Block processed: ${bn}`);

  } catch (err) {
    console.error(`❌ Error processing block ${blockNumber}:`, err);
    throw err;
  } finally {
    dbClient.release(); // 🔥 VERY IMPORTANT
  }
}

// ===============================
// 🚀 MAIN LOOP
// ===============================

async function main() {
  console.log("🚀 Nexvel Indexer Started");

  await initIndexerState();

  let currentBlock = await getLastProcessedBlock();

  while (true) {
    try {
      const latest = await client.getBlockNumber();
      const latestNumber = Number(latest);

      const safeBlock = latestNumber - CONFIRMATIONS;

      if (currentBlock >= safeBlock) {
        await new Promise((res) => setTimeout(res, 2000));
        continue;
      }

      while (currentBlock < safeBlock) {
        currentBlock++;
        await processBlock(currentBlock);
      }

    } catch (err) {
      console.error("❌ Indexer error:", err);
      await new Promise((res) => setTimeout(res, 3000));
    }
  }
}

main().catch(console.error);