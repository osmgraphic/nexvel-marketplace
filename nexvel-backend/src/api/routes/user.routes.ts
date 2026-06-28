import { Router } from "express";
import { pool } from "../../database/db"

const router = Router();

router.get("/:wallet/nfts", async (req, res) => {
  try {
    const wallet = req.params.wallet.toLowerCase();

    const result = await pool.query(
      `SELECT * FROM owners WHERE owner_address=$1`,
      [wallet]
    );

    res.json(result.rows);

  } catch (err) {
    res.status(500).json({ error: "Failed to fetch user NFTs" });
  }
});

router.get("/:wallet/activity", async (req, res) => {
  try {
    const wallet = req.params.wallet.toLowerCase();

    const result = await pool.query(
      `
      SELECT *
      FROM activities
      WHERE from_address=$1 OR to_address=$1
      ORDER BY block_number DESC
      `,
      [wallet]
    );

    res.json(result.rows);

  } catch (err) {
    res.status(500).json({ error: "Failed to fetch user activity" });
  }
});

export default router;