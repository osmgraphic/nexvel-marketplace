import { container } from "../core/container";
import { initContracts } from "./contracts";

import { initEnvironment } from "./environment";
import { initDatabase } from "./database";
import { initBlockchain } from "./blockchain";
import { initRegistry } from "./registry";
import { initSocketLayer } from "./socket";
import { initInterfaces } from "./interfaces";

export async function bootstrap() {
  console.log("==================================");
  console.log("🚀 Nexvel Marketplace Bootstrap");
  console.log("==================================");

await initEnvironment();

await initDatabase();

await initBlockchain();

await initRegistry();

await initContracts();

await initInterfaces();

await initSocketLayer();

  container.initialized = true;

  console.log("==================================");
  console.log("✅ Bootstrap Completed");
  console.log("==================================");
}