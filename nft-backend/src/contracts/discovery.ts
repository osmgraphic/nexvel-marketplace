import { getRegistryAddresses } from "../registry";
import type { ProtocolContracts } from "./types";

let cachedContracts: ProtocolContracts | null = null;

export async function discoverContracts(): Promise<ProtocolContracts> {
  if (cachedContracts) {
    return cachedContracts;
  }

  cachedContracts = getRegistryAddresses();

  console.log("📦 Contract Discovery");
  console.table(cachedContracts);

  return cachedContracts;
}

export function getContracts(): ProtocolContracts {
  if (!cachedContracts) {
    throw new Error("Contracts have not been discovered.");
  }

  return cachedContracts;
}