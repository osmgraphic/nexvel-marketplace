import { addressSchema } from "../utils/validation";
import {
  getUserNFTs,
  getUserActivity,
  getUserPortfolio
} from "./user.service";

import { redis } from "../../utils/redis";

// 🔥 GET /user/:wallet/portfolio
export async function fetchUserPortfolio(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.wallet);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid wallet address" });
    }

    const wallet = parsed.data.toLowerCase();

    const cacheKey = `user:portfolio:${wallet}`;

    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (e) {
      console.error("Redis parse error:", e);
    }

    const data = await getUserPortfolio(wallet);

    await redis.set(cacheKey, JSON.stringify(data), "EX", 30);

    res.json(data);

  } catch (err) {
    console.error("❌ fetchUserPortfolio:", err);
    res.status(500).json({ error: "Failed to fetch portfolio" });
  }
}

// 👤 GET /user/:wallet/nfts
export async function fetchUserNFTs(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.wallet);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid wallet address" });
    }

    const wallet = parsed.data.toLowerCase();

    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const data = await getUserNFTs(wallet, limit, offset);

    res.json(data);

  } catch (err) {
    console.error("❌ fetchUserNFTs:", err);
    res.status(500).json({ error: "Failed to fetch user NFTs" });
  }
}

// 📊 GET /user/:wallet/activity
export async function fetchUserActivity(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.wallet);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid wallet address" });
    }

    const wallet = parsed.data.toLowerCase();

    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const data = await getUserActivity(wallet, limit, offset);

    res.json(data);

  } catch (err) {
    console.error("❌ fetchUserActivity:", err);
    res.status(500).json({ error: "Failed to fetch user activity" });
  }
}