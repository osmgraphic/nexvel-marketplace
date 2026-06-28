import { registry } from "./client";
import type { RegistryAddresses, RegistryMetadata } from "./types";

let cachedAddresses: RegistryAddresses | null = null;
let cachedMetadata: RegistryMetadata | null = null;

export async function loadRegistry(): Promise<RegistryAddresses> {
  if (cachedAddresses) {
    return cachedAddresses;
  }

const metadata = (await registry.read.metadata()) as [
  string,
  bigint,
  bigint,
  boolean
];

  if (!metadata[3]) {
    throw new Error("Registry is not initialized.");
  }

const addresses = (await registry.read.allAddresses()) as [
  `0x${string}`,
  `0x${string}`,
  `0x${string}`,
  `0x${string}`,
  `0x${string}`
];

  cachedMetadata = {
    protocol: metadata[0],
    version: metadata[1],
    chainId: metadata[2],
    initialized: metadata[3],
  };

  cachedAddresses = {
    security: addresses[0],
    marketplace: addresses[1],
    launchpad: addresses[2],
    erc1155: addresses[3],
    nftFactory: addresses[4],
  };

  console.log("====================================");
  console.log("📦 Registry Loaded");
  console.log(`Protocol : ${cachedMetadata.protocol}`);
  console.log(`Version  : ${cachedMetadata.version}`);
  console.log(`Chain ID : ${cachedMetadata.chainId}`);
  console.log("====================================");

  console.table(cachedAddresses);

  return cachedAddresses;
}

export function getRegistryAddresses(): RegistryAddresses {
  if (!cachedAddresses) {
    throw new Error("Registry has not been loaded.");
  }

  return cachedAddresses;
}

export function getRegistryMetadata(): RegistryMetadata {
  if (!cachedMetadata) {
    throw new Error("Registry has not been loaded.");
  }

  return cachedMetadata;
}