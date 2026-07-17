import { registry } from "./client";
import type {
  RegistryAddresses,
  RegistryMetadata,
} from "./types";

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

  const addresses = (await registry.read.allAddresses()) as [
    `0x${string}`,
    `0x${string}`,
    `0x${string}`,
    `0x${string}`,
    `0x${string}`
  ];

  const registryMetadata: RegistryMetadata = {
    protocol: metadata[0],
    version: Number(metadata[1]),
    chainId: Number(metadata[2]),
    initialized: metadata[3],
  };

  const registryAddresses: RegistryAddresses = {
    security: addresses[0],
    marketplace: addresses[1],
    launchpad: addresses[2],
    erc1155: addresses[3],
    nftFactory: addresses[4],
  };

  cachedMetadata = registryMetadata;
  cachedAddresses = registryAddresses;

  console.log("====================================");
  console.log("📦 Registry Loaded");
  console.log(`Protocol     : ${registryMetadata.protocol}`);
  console.log(`Version      : ${registryMetadata.version}`);
  console.log(`Chain ID     : ${registryMetadata.chainId}`);
  console.log(`Initialized  : ${registryMetadata.initialized}`);
  console.log("====================================");

  console.table(registryAddresses);

  if (!registryMetadata.initialized) {
    console.warn("⚠️ Registry is not fully initialized.");
  }

  return registryAddresses;
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