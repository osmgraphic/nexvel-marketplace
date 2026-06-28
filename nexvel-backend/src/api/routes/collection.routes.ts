import { Router } from "express";
import { pool } from "../../database/db"
import { fetchCollectionFull } from "../controllers/collection.controller";

const router = Router();

router.get("/:contract/full", fetchCollectionFull);

router.get("/:contract/floor", async (req, res) => {
  try {
    const contract = req.params.contract.toLowerCase();

    const result = await pool.query(
      `
      SELECT MIN(price) AS floor_price
      FROM listings
      WHERE contract_address=$1 AND status='ACTIVE'
      `,
      [contract]
    );

    res.json(result.rows[0]);

  } catch (err) {
    res.status(500).json({ error: "Failed to get floor price" });
  }
});

router.get("/:contract/stats", async (req, res) => {
  try {
    const contract = req.params.contract.toLowerCase();

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
    res.status(500).json({ error: "Stats failed" });
  }
});

export default router;