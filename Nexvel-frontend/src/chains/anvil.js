import { defineChain } from "viem";

export const anvil = defineChain({
  id: 31337,
  name: "Anvil Local",
  network: "anvil",
  nativeCurrency: { name: "ETH", symbol: "ETH", decimals: 18 },
  rpcUrls: {
    default: { http: ["http://127.0.0.1:8545"] }   // replace with your RPC
  }
});
