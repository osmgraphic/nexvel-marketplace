import { createPublicClient, http } from "viem";

import { env } from "../config/env";
import { chain } from "../config/chains";

export const client = createPublicClient({
  chain,
  transport: http(env.RPC_URL),
});

export async function testRpcConnection() {
  try {
    const block = await client.getBlockNumber();

    console.log(
      `✅ Connected to ${client.chain.name} | Latest Block: ${block}`
    );
  } catch (err) {
    console.error("❌ RPC Error:", err);
  }
}