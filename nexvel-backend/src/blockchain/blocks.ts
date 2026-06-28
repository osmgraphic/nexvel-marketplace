import { pool } from "../database/db.js";

// ===============================
// 🧠 INIT
// ===============================

export async function initIndexerState(startBlock: number = 0) {
  await pool.query(
    `
    INSERT INTO indexer_state (id, last_processed_block)
    VALUES (1, $1)
    ON CONFLICT (id) DO NOTHING
    `,
    [startBlock]
  );
}

// ===============================
// 📦 PROGRESS TRACKING
// ===============================

export async function getLastProcessedBlock(): Promise<number> {
  const result = await pool.query(
    "SELECT last_processed_block FROM indexer_state WHERE id = 1"
  );

  if (result.rows.length === 0) {
    throw new Error("❌ indexer_state not initialized.");
  }

  return Number(result.rows[0].last_processed_block);
}

export async function updateLastProcessedBlock(block: number) {
  await pool.query(
    `
    UPDATE indexer_state
    SET last_processed_block = $1
    WHERE id = 1 AND last_processed_block < $1
    `,
    [block]
  );
}

// ===============================
// 🔗 BLOCK STORAGE
// ===============================

export async function saveBlock(
  blockNumber: number,
  blockHash: string,
  parentHash: string
) {
  await pool.query(
    `
    INSERT INTO blocks (block_number, block_hash, parent_hash)
    VALUES ($1, $2, $3)
    ON CONFLICT (block_number) DO UPDATE
    SET block_hash = EXCLUDED.block_hash,
        parent_hash = EXCLUDED.parent_hash
    `,
    [blockNumber, blockHash, parentHash]
  );
}

export async function getBlock(blockNumber: number) {
  const res = await pool.query(
    `SELECT * FROM blocks WHERE block_number = $1`,
    [blockNumber]
  );

  return res.rows[0] || null;
}

// ===============================
// ⚠️ REORG DETECTION
// ===============================

export async function isReorg(
  blockNumber: number,
  blockHash: string
): Promise<boolean> {
  const existing = await getBlock(blockNumber);

  if (!existing) return false;

  return existing.block_hash !== blockHash;
}

// ===============================
// 🔥 ROLLBACK SYSTEM
// ===============================

export async function rollbackFromBlock(blockNumber: number) {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    console.log(`⚠️ Reorg detected. Rolling back from block ${blockNumber}`);

    // delete indexed data
    await client.query(
      `DELETE FROM activities WHERE block_number >= $1`,
      [blockNumber]
    );

    // delete block history
    await client.query(
      `DELETE FROM blocks WHERE block_number >= $1`,
      [blockNumber]
    );

    // reset indexer state
    await client.query(
      `
      UPDATE indexer_state
      SET last_processed_block = $1
      WHERE id = 1
      `,
      [blockNumber - 1]
    );

    await client.query("COMMIT");

  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}