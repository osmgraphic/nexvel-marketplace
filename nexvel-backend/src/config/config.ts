import dotenv from "dotenv"

dotenv.config()

export const config = {
  rpcUrl: process.env.RPC_URL as string,
  databaseUrl: process.env.DATABASE_URL as string,
  marketplaceAddress: process.env.MARKETPLACE_ADDRESS as `0x${string}`
}