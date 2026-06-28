import { container } from "../core/container";

import { initEnvironment } from "./environment";
import { initDatabase } from "./database";
import { initBlockchain } from "./blockchain";
import { initRegistry } from "./registry";
import { initSocketLayer } from "./socket";

export async function bootstrap() {
  console.log("🚀 Starting Nexvel Bootstrap...");

  await initEnvironment();

  await initDatabase();

  await initBlockchain();

  await initRegistry();

  await initSocketLayer();

  container.initialized = true;

  console.log("✅ Bootstrap Completed");
}