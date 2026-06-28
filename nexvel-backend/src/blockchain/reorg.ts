import { pool } from "../database/db";
import { client as rpc } from "./client";

// 🔍 Check if block matches stored hash
export async function isReorg(blockNumber: number, blockHash: string) {
  const res = await pool.query(
    `SELECT block_hash FROM blocks WHERE block_number = $1`,
    [blockNumber]
  );

  if (res.rowCount === 0) return false;

  return res.rows[0].block_hash !== blockHash;
}