import { pool } from "../database/db";

// 🔥 delete everything from bad block onwards
export async function rollbackFromBlock(blockNumber: number) {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    console.log(`⚠️ Reorg detected. Rolling back from block ${blockNumber}`);

    // delete activities
    await client.query(
      `DELETE FROM activities WHERE block_number >= $1`,
      [blockNumber]
    );

    // delete blocks
    await client.query(
      `DELETE FROM blocks WHERE block_number >= $1`,
      [blockNumber]
    );

    await client.query("COMMIT");

  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}