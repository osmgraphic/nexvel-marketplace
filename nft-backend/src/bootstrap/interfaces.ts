import { initializeInterfaces } from "../contracts/interfaceManager";

export async function initInterfaces() {
  initializeInterfaces();

  console.log("✅ Interfaces Initialized");
}