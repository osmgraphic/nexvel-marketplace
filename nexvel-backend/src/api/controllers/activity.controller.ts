import { pool } from "../../database/db";
import { redis } from "../../utils/redis";
import { nftSchema } from "../utils/validation";

// 🔥 GET /activity
export async function fetchActivity(req: any, res: any) {
  try {
    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const cacheKey = `activity:${limit}:${offset}`;

    // 🔥 cache
    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (e) {
      console.error("Redis error:", e);
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

    await redis.set(cacheKey, JSON.stringify(result.rows), "EX", 15);

    res.json(result.rows);

  } catch (err) {
    console.error("❌ fetchActivity:", err);
    res.status(500).json({ error: "Failed to fetch activity" });
  }
}

// 🔥 GET /activity/:contract/:tokenId
export async function fetchNFTActivity(req: any, res: any) {
  try {
    const parsed = nftSchema.safeParse(req.params);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid params" });
    }

    const contract = parsed.data.contract.toLowerCase();
    const tokenId = parsed.data.tokenId.toString();

    const result = await pool.query(
      `
      SELECT *
      FROM activities
      WHERE contract_address=$1 AND token_id=$2
      ORDER BY block_number DESC
      LIMIT 50
      `,
      [contract, tokenId]
    );

    res.json(result.rows);

  } catch (err) {
    console.error("❌ fetchNFTActivity:", err);
    res.status(500).json({ error: "Failed to fetch NFT activity" });
  }
}