import { pool } from "../../database/db";
import { addressSchema } from "../utils/validation";

export async function fetchUserNFTs(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.wallet);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid wallet",
      });
    }

    const wallet = parsed.data.toLowerCase();

    const result = await pool.query(
      `
      SELECT *
      FROM owners
      WHERE owner_address = $1
      `,
      [wallet]
    );

    res.json(result.rows);

  } catch (err) {
    console.error(err);

    res.status(500).json({
      error: "Failed to fetch user NFTs",
    });
  }
}

export async function fetchUserActivity(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.wallet);

    if (!parsed.success) {
      return res.status(400).json({
        error: "Invalid wallet",
      });
    }

    const wallet = parsed.data.toLowerCase();

    const result = await pool.query(
      `
      SELECT *
      FROM activities
      WHERE from_address = $1
         OR to_address = $1
      ORDER BY block_number DESC
      `,
      [wallet]
    );

    res.json(result.rows);

  } catch (err) {
    console.error(err);

    res.status(500).json({
      error: "Failed to fetch user activity",
    });
  }
}