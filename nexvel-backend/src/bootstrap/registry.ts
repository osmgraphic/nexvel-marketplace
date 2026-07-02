import { container } from "../core/container";
import {
  loadRegistry,
  getRegistryMetadata,
} from "../registry";

export async function initRegistry() {
  await loadRegistry();

  const metadata = getRegistryMetadata();

  console.log(
    `📦 Registry: ${metadata.protocol} v${metadata.version}`
  );

  console.log(
    `🌐 Chain ID: ${metadata.chainId}`
  );

  container.registry = true;

  console.log("✅ Registry Initialized");
}