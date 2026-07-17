import dotenv from "dotenv";

dotenv.config();

function required(name: string): string {
  const value = process.env[name];

  if (!value) {
    throw new Error(`❌ Missing required environment variable: ${name}`);
  }

  return value;
}

export const env = {
  NODE_ENV: process.env.NODE_ENV ?? "development",
  PORT: Number(process.env.PORT ?? "4000"),

  RPC_URL: required("RPC_URL"),

  DATABASE_URL: required("DATABASE_URL"),
  REDIS_URL: required("REDIS_URL"),

  JWT_SECRET: required("JWT_SECRET"),

REGISTRY_ADDRESS: required("REGISTRY_ADDRESS") as `0x${string}`,

MARKETPLACE_ADDRESS: required("MARKETPLACE_ADDRESS") as `0x${string}`,
FACTORY_ADDRESS: required("FACTORY_ADDRESS") as `0x${string}`,
LAUNCHPAD_ADDRESS: required("LAUNCHPAD_ADDRESS") as `0x${string}`,
ERC721_IMPL_ADDRESS: required("ERC721_IMPL_ADDRESS") as `0x${string}`,
ERC721A_IMPL_ADDRESS: required("ERC721A_IMPL_ADDRESS") as `0x${string}`,
ERC1155_ADDRESS: required("ERC1155_ADDRESS") as `0x${string}`,

  CHAIN_ID: Number(process.env.CHAIN_ID ?? "11155111"),

  INDEXER_CONFIRMATIONS: Number(
    process.env.INDEXER_CONFIRMATIONS ?? "5"
  ),

  INDEXER_POLL_INTERVAL: Number(
    process.env.INDEXER_POLL_INTERVAL ?? "2000"
  ),

  LOG_LEVEL: process.env.LOG_LEVEL ?? "info",
};