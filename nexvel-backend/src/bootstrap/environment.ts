import { env } from "../config/env";

export async function initEnvironment() {
  console.log("🌍 Environment Loaded");
  return env;
}