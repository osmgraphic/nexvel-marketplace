import {
  searchNFTs,
  searchCollections,
  searchListings,
  globalSearch
} from "./search.service";

import { redis } from "../../utils/redis";

// 🔍 sanitize query
function normalizeQuery(q: any): string | null {
  if (!q || typeof q !== "string") return null;
  const trimmed = q.trim().toLowerCase();
  if (trimmed.length < 2) return null; // prevent spam / useless queries
  return trimmed;
}

// 🔍 GET /search?q=
export async function searchAll(req: any, res: any) {
  try {
    const q = normalizeQuery(req.query.q);
    if (!q) return res.status(400).json({ error: "Invalid query" });

    const limit = Math.min(Number(req.query.limit) || 20, 50);

    const cacheKey = `search:all:${q}:${limit}`;

    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (e) {
      console.error("Redis error:", e);
    }

    const data = await globalSearch(q, limit);

    await redis.set(cacheKey, JSON.stringify(data), "EX", 30);

    res.json(data);

  } catch (err) {
    console.error("❌ searchAll:", err);
    res.status(500).json({ error: "Search failed" });
  }
}

// 🎨 NFTs only
export async function searchNFTController(req: any, res: any) {
  try {
    const q = normalizeQuery(req.query.q);
    if (!q) return res.status(400).json({ error: "Invalid query" });

    const limit = Math.min(Number(req.query.limit) || 20, 50);

    const data = await searchNFTs(q, limit);

    res.json(data);

  } catch (err) {
    console.error("❌ searchNFTController:", err);
    res.status(500).json({ error: "Search failed" });
  }
}

// 📦 Collections only
export async function searchCollectionController(req: any, res: any) {
  try {
    const q = normalizeQuery(req.query.q);
    if (!q) return res.status(400).json({ error: "Invalid query" });

    const limit = Math.min(Number(req.query.limit) || 20, 50);

    const data = await searchCollections(q, limit);

    res.json(data);

  } catch (err) {
    console.error("❌ searchCollectionController:", err);
    res.status(500).json({ error: "Search failed" });
  }
}

// 🛒 Listings only
export async function searchListingController(req: any, res: any) {
  try {
    const q = normalizeQuery(req.query.q);
    if (!q) return res.status(400).json({ error: "Invalid query" });

    const limit = Math.min(Number(req.query.limit) || 20, 50);

    const data = await searchListings(q, limit);

    res.json(data);

  } catch (err) {
    console.error("❌ searchListingController:", err);
    res.status(500).json({ error: "Search failed" });
  }
}