import { container } from "../core/container";

export async function initSocketLayer() {
  console.log("🔌 Socket bootstrap skipped");

  container.socket = true;
}