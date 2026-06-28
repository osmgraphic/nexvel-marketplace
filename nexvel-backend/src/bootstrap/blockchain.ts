import { testRpcConnection } from "../blockchain/client";
import { container } from "../core/container";

export async function initBlockchain() {
  await testRpcConnection();

  container.blockchain = true;

  console.log("✅ Blockchain Connected");
}