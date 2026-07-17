import {
  getNFT,
  getUserNFTs,
  getCollectionNFTs,
  getNFTFull
} from "../../services/nftService";

import { nftSchema, addressSchema } from "../utils/validation";
import { redis } from "../../utils/redis";

// 🔥 GET /nft/:contract/:tokenId/full
export async function fetchNFTFull(req: any, res: any) {
  try {
    const parsed = nftSchema.safeParse(req.params);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid params" });
    }

    const contract = parsed.data.contract.toLowerCase();
    const tokenId = parsed.data.tokenId.toString();

    const cacheKey = `nft:full:${contract}:${tokenId}`;

    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (e) {
      console.error("Redis parse error:", e);
    }

    const data = await getNFTFull(contract, tokenId);

    if (data) {
      await redis.set(cacheKey, JSON.stringify(data), "EX", 60);
    }

    res.json(data);

  } catch (err) {
    console.error("❌ fetchNFTFull:", err);
    res.status(500).json({ error: "Failed to fetch NFT full data" });
  }
}

// 🎨 GET /nft/:contract/:tokenId
export async function fetchNFT(req: any, res: any) {
  try {
    const parsed = nftSchema.safeParse(req.params);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid params" });
    }

    const contract = parsed.data.contract.toLowerCase();
    const tokenId = parsed.data.tokenId.toString();

    const cacheKey = `nft:${contract}:${tokenId}`;

    try {
      const cached = await redis.get(cacheKey);
      if (cached) return res.json(JSON.parse(cached));
    } catch (e) {
      console.error("Redis parse error:", e);
    }

    const data = await getNFT(contract, tokenId);

    if (data) {
      await redis.set(cacheKey, JSON.stringify(data), "EX", 60);
    }

    res.json(data || {});

  } catch (err) {
    console.error("❌ fetchNFT:", err);
    res.status(500).json({ error: "Failed to fetch NFT" });
  }
}

// 👤 GET /nft/user/:address
export async function fetchUserNFTs(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.address);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid address" });
    }

    const address = parsed.data.toLowerCase();

    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const data = await getUserNFTs(address, limit, offset);

    res.json(data);

  } catch (err) {
    console.error("❌ fetchUserNFTs:", err);
    res.status(500).json({ error: "Failed to fetch user NFTs" });
  }
}

// 📦 GET /nft/collection/:contract
export async function fetchCollectionNFTs(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.contract);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid contract" });
    }

    const contract = parsed.data.toLowerCase();

    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const data = await getCollectionNFTs(contract, limit, offset);

    res.json(data);

  } catch (err) {
    console.error("❌ fetchCollectionNFTs:", err);
    res.status(500).json({ error: "Failed to fetch collection NFTs" });
  }
}