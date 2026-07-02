import { pool } from "../database/db";
import { redis } from "../utils/redis";

export async function getActivity(
  limit: number,
  offset: number
) {
  const cacheKey = `activity:${limit}:${offset}`;

  const cached = await redis.get(cacheKey);

  if (cached) {
    return JSON.parse(cached);
  }

  const result = await pool.query(
    `
    SELECT *
    FROM activities
    ORDER BY block_number DESC
    LIMIT $1 OFFSET $2
    `,
    [limit, offset]
  );

  await redis.set(
    cacheKey,
    JSON.stringify(result.rows),
    "EX",
    15
  );

  return result.rows;
}

export async function getNFTActivity(
  contract: string,
  tokenId: string
) {
  const result = await pool.query(
    `
    SELECT *
    FROM activities
    WHERE contract_address=$1
      AND token_id=$2
    ORDER BY block_number DESC
    LIMIT 50
    `,
    [contract, tokenId]
  );

  return result.rows;
}