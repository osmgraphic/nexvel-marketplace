import {
  getAllSales,
  getNFTSales,
  getUserPurchases,
  getTotalVolume
} from "../../services/saleService";

import { nftSchema, addressSchema } from "../utils/validation";
import { redis } from "../../utils/redis";

// 💰 GET /sales
export async function fetchSales(req: any, res: any) {
  try {
    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const cacheKey = `sales:${limit}:${offset}`;

    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (e) {
      console.error("Redis parse error:", e);
    }

    const data = await getAllSales(limit, offset);

    await redis.set(cacheKey, JSON.stringify(data), "EX", 30);

    res.json(data);

  } catch (err) {
    console.error("❌ fetchSales:", err);
    res.status(500).json({ error: "Failed to fetch sales" });
  }
}

// 📊 GET /sales/:contract/:tokenId
export async function fetchNFTSales(req: any, res: any) {
  try {
    const parsed = nftSchema.safeParse(req.params);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid params" });
    }

    const contract = parsed.data.contract.toLowerCase();
    const tokenId = parsed.data.tokenId.toString();

    const cacheKey = `sales:nft:${contract}:${tokenId}`;

    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (e) {
      console.error("Redis parse error:", e);
    }

    const data = await getNFTSales(contract, tokenId);

    await redis.set(cacheKey, JSON.stringify(data), "EX", 60);

    res.json(data);

  } catch (err) {
    console.error("❌ fetchNFTSales:", err);
    res.status(500).json({ error: "Failed to fetch NFT sales" });
  }
}

// 👤 GET /sales/user/:address
export async function fetchUserPurchases(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.address);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid address" });
    }

    const address = parsed.data.toLowerCase();

    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const data = await getUserPurchases(address, limit, offset);

    res.json(data);

  } catch (err) {
    console.error("❌ fetchUserPurchases:", err);
    res.status(500).json({ error: "Failed to fetch purchases" });
  }
}

// 📈 GET /sales/volume
export async function fetchVolume(req: any, res: any) {
  try {
    const cacheKey = `sales:volume`;

    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (e) {
      console.error("Redis parse error:", e);
    }

    const data = await getTotalVolume();

    await redis.set(cacheKey, JSON.stringify(data), "EX", 60);

    res.json(data);

  } catch (err) {
    console.error("❌ fetchVolume:", err);
    res.status(500).json({ error: "Failed to fetch volume" });
  }
}