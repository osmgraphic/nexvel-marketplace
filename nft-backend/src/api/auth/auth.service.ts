import { randomBytes } from "crypto";
import jwt from "jsonwebtoken";
import { ethers } from "ethers";

const JWT_SECRET = "supersecret" // move to .env later

// 🔐 Generate nonce
export function generateNonce() {
  return randomBytes(16).toString("hex")
}

// ✍️ Create SIWE message
export function createMessage(
  address: string,
  nonce: string,
  opts?: { domain?: string; chainId?: number }
) {
  const domain = opts?.domain || "nexvel.app";
  const chainId = opts?.chainId || 1;

  return `Sign this message to login:

Domain: ${domain}
Wallet: ${address}
Nonce: ${nonce}
Chain ID: ${chainId}`;
}

// ✅ Verify signature
export function verifySignature(
  message: string,
  signature: string,
  address: string
) {
  const recovered = ethers.verifyMessage(message, signature)
  return recovered.toLowerCase() === address.toLowerCase()
}

// 🎟️ Generate JWT
export function generateToken(address: string) {
  return jwt.sign({ address }, JWT_SECRET, {
    expiresIn: "7d"
  })
}