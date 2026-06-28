import { pool } from "../database/db";

// 💰 Get all sales
export async function getAllSales(limit = 50) {
  const { rows } = await pool.query(
    `
    SELECT
      contract_address,
      token_id,
      buyer,
      seller,
      price,
      created_at
    FROM sales
    ORDER BY created_at DESC
    LIMIT $1
    `,
    [limit]
  );
  return rows;
}

// 📊 Get sales for NFT
export async function getNFTSales(contract: string, tokenId: string) {
  const { rows } = await pool.query(
    `
    SELECT buyer, seller, price, created_at
    FROM sales
    WHERE contract_address = $1 AND token_id = $2
    ORDER BY created_at DESC
    LIMIT 50
    `,
    [contract, tokenId]
  );
  return rows;
}

// 👤 Get user purchases
export async function getUserPurchases(address: string, limit: number, offset: number) {
  const result = await pool.query(
    `
    SELECT *
    FROM sales
    WHERE buyer=$1
    ORDER BY block_number DESC
    LIMIT $2 OFFSET $3
    `,
    [address, limit, offset]
  );

  return result.rows;
}

// 💸 Total volume (analytics)
export async function getTotalVolume() {
  // if this becomes hot, move to a pre-aggregated table
  const { rows } = await pool.query(
    `SELECT COALESCE(SUM(price), 0) AS volume FROM sales`
  );
  return rows[0];
}