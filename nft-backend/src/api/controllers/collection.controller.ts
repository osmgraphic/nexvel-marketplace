import { addressSchema } from "../utils/validation";
import { getCollectionFull } from "../../services/collectionService";
import { getOrSetCache } from "../../utils/cache";

import { pool } from "../../database/db";

export async function fetchCollectionFloor(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.contract);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid contract",
      });
    }

    const contract = parsed.data.toLowerCase();

    const result = await pool.query(
      `
      SELECT MIN(price) AS floor_price
      FROM listings
      WHERE contract_address=$1
      AND status='ACTIVE'
      `,
      [contract]
    );

    res.json(result.rows[0]);

  } catch (err) {
    console.error(err);

    res.status(500).json({
      error: "Failed to fetch floor price",
    });
  }
}

export async function fetchCollectionStats(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.contract);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid contract",
      });
    }

    const contract = parsed.data.toLowerCase();

    const result = await pool.query(
      `
      SELECT
        COUNT(*) FILTER (WHERE status='ACTIVE') AS total_listings,
        MIN(price) FILTER (WHERE status='ACTIVE') AS floor_price,
        COUNT(*) AS total_items
      FROM listings
      WHERE contract_address=$1
      `,
      [contract]
    );

    res.json(result.rows[0]);

  } catch (err) {
    console.error(err);

    res.status(500).json({
      error: "Failed to fetch collection stats",
    });
  }
}

// 🔥 GET /collection/:contract/full
export async function fetchCollectionFull(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.contract);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid contract" });
    }

    const contract = parsed.data.toLowerCase();

    const data = await getOrSetCache(
      `collection:full:${contract}`,
      60,
      () => getCollectionFull(contract)
    );

    res.json(data);

  } catch (err) {
    console.error("❌ fetchCollectionFull:", err);
    res.status(500).json({ error: "Failed to fetch collection" });
  }
}