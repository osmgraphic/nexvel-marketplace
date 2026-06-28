import {
  generateNonce,
  createMessage,
  verifySignature,
  generateToken
} from "./auth.service";
import { redis } from "../../utils/redis";
import { addressSchema } from "../utils/validation";

// 🔥 1️⃣ Request message
export async function requestMessage(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.body.address);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid address" });
    }

    const address = parsed.data.toLowerCase();

    // 🔐 Optional: basic rate-limit (per address)
    const rlKey = `auth:rl:${address}`;
    const count = await redis.incr(rlKey);
    if (count === 1) await redis.expire(rlKey, 60); // 1 min window
    if (count > 10) {
      return res.status(429).json({ error: "Too many requests" });
    }

    const nonce = generateNonce();

    // ✅ Store nonce (5 min TTL)
    const nonceKey = `auth:nonce:${address}`;
    await redis.set(nonceKey, nonce, "EX", 300);

    // 🔐 Bind message to your app (prevents cross-app replay)
    const message = createMessage(address, nonce, {
      domain: process.env.APP_DOMAIN || "nexvel.app",
      chainId: Number(process.env.CHAIN_ID || 1),
    });

    res.json({ message });

  } catch (err) {
    console.error("❌ requestMessage:", err);
    res.status(500).json({ error: "Failed to generate message" });
  }
}

// 🔥 2️⃣ Verify signature
export async function verify(req: any, res: any) {
  try {
    const addrParsed = addressSchema.safeParse(req.body.address);
    const signature = req.body.signature;

    if (!addrParsed.success || typeof signature !== "string" || signature.length < 100) {
      return res.status(400).json({ error: "Invalid input" });
    }

    const address = addrParsed.data.toLowerCase();
    const nonceKey = `auth:nonce:${address}`;

    // 🔒 Get + delete nonce atomically (best effort)
    const nonce = await redis.get(nonceKey);
    if (!nonce) {
      return res.status(400).json({ error: "Nonce expired or not found" });
    }

    // delete first to avoid replay if verification is slow
    await redis.del(nonceKey);

    const message = createMessage(address, nonce, {
      domain: process.env.APP_DOMAIN || "nexvel.app",
      chainId: Number(process.env.CHAIN_ID || 1),
    });

    const isValid = verifySignature(message, signature, address);

    if (!isValid) {
      return res.status(401).json({ error: "Invalid signature" });
    }

    const token = generateToken(address);

    res.json({ token });

  } catch (err) {
    console.error("❌ verify:", err);
    res.status(500).json({ error: "Verification failed" });
  }
}