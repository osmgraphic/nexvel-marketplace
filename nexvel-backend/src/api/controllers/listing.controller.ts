import {
  getActiveListings,
  getListing,
  getUserListings,
  cancelListing
} from "../../services/listingService";

import { nftSchema, addressSchema } from "../utils/validation";
import { redis } from "../../utils/redis";

// 🔥 GET /listings
export async function fetchListings(req: any, res: any) {
  try {
    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const cacheKey = `listings:active:${limit}:${offset}`;

    // 🔥 cache
    const cached = await redis.get(cacheKey);
    if (cached) return res.json(JSON.parse(cached));

    const data = await getActiveListings(limit, offset);

    await redis.set(cacheKey, JSON.stringify(data), "EX", 15);

    res.json(data);

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch listings" });
  }
}

// 🔍 GET /listings/:contract/:tokenId
export async function fetchListing(req: any, res: any) {
  try {
    const parsed = nftSchema.safeParse(req.params);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid params" });
    }

    const { contract, tokenId } = parsed.data;

    const cacheKey = `listing:${contract}:${tokenId}`;

    const cached = await redis.get(cacheKey);
    if (cached) return res.json(JSON.parse(cached));

    const data = await getListing(contract, tokenId);

    await redis.set(cacheKey, JSON.stringify(data || {}), "EX", 30);

    res.json(data || {});
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch listing" });
  }
}

// 👤 GET /listings/user/:address
export async function fetchUserListings(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.address);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid address" });
    }

    const address = parsed.data;

    const data = await getUserListings(address);

    res.json(data);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch user listings" });
  }
}

// ❌ POST /listings/cancel
export async function cancelListingController(req: any, res: any) {
  try {
    const parsed = nftSchema.safeParse(req.body);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid input" });
    }

    if (!req.user?.address) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const { contract, tokenId } = parsed.data;
    const seller = req.user.address;

    await cancelListing(contract, tokenId, seller);

    // 🔥 invalidate cache
    const pipe = redis.pipeline();
    pipe.del("listings:active");
    pipe.del(`listing:${contract}:${tokenId}`);
    await pipe.exec();

    res.json({ message: "Listing cancelled" });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to cancel listing" });
  }
}