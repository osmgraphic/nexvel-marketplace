import type { Chain } from "viem";
import { env } from "./env";

import {
  mainnet,
  sepolia,
  polygon,
  polygonAmoy,
  base,
  baseSepolia,
  bsc,
  bscTestnet,
  arbitrum,
  arbitrumSepolia,
} from "viem/chains";

const CHAINS: Readonly<Record<number, Chain>> = {
  // Ethereum
  1: mainnet,
  11155111: sepolia,

  // Polygon
  137: polygon,
  80002: polygonAmoy,

  // Base
  8453: base,
  84532: baseSepolia,

  // BNB Chain
  56: bsc,
  97: bscTestnet,

  // Arbitrum
  42161: arbitrum,
  421614: arbitrumSepolia,
};

export const chain: Chain = (() => {
  const selectedChain = CHAINS[env.CHAIN_ID];

  if (!selectedChain) {
    const supported = Object.keys(CHAINS).join(", ");

    throw new Error(
      `Unsupported CHAIN_ID: ${env.CHAIN_ID}. Supported: ${supported}`
    );
  }

  return selectedChain;
})();