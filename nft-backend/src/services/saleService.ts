import { pool } from "../database/db";

// 💰 Get all sales
export async function getAllSales(
  limit = 20,
  offset = 0
) {
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
    LIMIT $1 OFFSET $2
    `,
    [limit, offset]
  );

  return rows;
}

// 📊 NFT sales
export async function getNFTSales(
  contract: string,
  tokenId: string
) {
  const { rows } = await pool.query(
    `
    SELECT
      buyer,
      seller,
      price,
      created_at
    FROM sales
    WHERE contract_address = $1
      AND token_id = $2
    ORDER BY created_at DESC
    LIMIT 50
    `,
    [contract.toLowerCase(), tokenId]
  );

  return rows;
}

// 👤 User purchases
export async function getUserPurchases(
  address: string,
  limit = 20,
  offset = 0
) {
  const { rows } = await pool.query(
    `
    SELECT *
    FROM sales
    WHERE buyer = $1
    ORDER BY block_number DESC
    LIMIT $2 OFFSET $3
    `,
    [address.toLowerCase(), limit, offset]
  );

  return rows;
}

// 📈 Total Volume
export async function getTotalVolume() {
  const { rows } = await pool.query(
    `
    SELECT COALESCE(SUM(price),0) AS volume
    FROM sales
    `
  );

  return rows[0];
}