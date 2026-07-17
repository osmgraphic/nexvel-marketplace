import { discoverContracts } from "../contracts/discovery";

export async function initContracts() {
  await discoverContracts();

  console.log("✅ Contract Discovery Initialized");
}