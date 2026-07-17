import { client } from "../blockchain/client";
import { processBlock } from "./processor";
import { updateLastProcessedBlock } from "../blockchain/blocks";

async function reindex(fromBlock: number, toBlock?: number) {
  console.log("🔄 Reindexing started...");

  const latest = Number(await client.getBlockNumber());
  const endBlock = toBlock ?? latest;

  console.log(`From: ${fromBlock} → To: ${endBlock}`);

  for (let block = fromBlock; block <= endBlock; block++) {
    try {
      await processBlock(block);
      await updateLastProcessedBlock(block);

      if (block % 10 === 0) {
        console.log(`✅ Synced till block ${block}`);
      }
    } catch (err) {
      console.error(`❌ Error at block ${block}`, err);
    }
  }

  console.log("✅ Reindex complete");
}

// 👉 Change start block if needed
const START_BLOCK = Number(process.argv[2]);

if (Number.isNaN(START_BLOCK)) {
  console.error("Usage: npm run reindex -- <startBlock>");
  process.exit(1);
}

reindex(START_BLOCK).catch(console.error);