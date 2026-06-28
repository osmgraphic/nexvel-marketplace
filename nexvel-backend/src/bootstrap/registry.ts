import { container } from "../core/container";
import { loadRegistry } from "../registry";

export async function initRegistry() {
  await loadRegistry();

  container.registry = true;

  console.log("✅ Registry Initialized");
}