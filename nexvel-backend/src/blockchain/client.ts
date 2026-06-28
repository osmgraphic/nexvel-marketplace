import { createPublicClient, http } from "viem";
import { sepolia } from "viem/chains";
import { env } from "../config/env";

export const client = createPublicClient({
  chain: sepolia,
  transport: http(env.RPC_URL),
});

// ✅ Debug function
export async function testRpcConnection() {
  try {
    const block = await client.getBlockNumber();
    console.log("✅ Latest Block:", block.toString());
  } catch (err) {
    console.error("❌ RPC Error:", err);
  }
}