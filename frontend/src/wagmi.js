import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'wagmi';
import {
  bsc,
  bscTestnet,
  mainnet,
  polygon,
} from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'Nexvel DApp',
  projectId: process.env.PROJECT_ID,   // Required for RainbowKit v2

  chains: [bsc, bscTestnet, mainnet, polygon],

  transports: {
    [bsc.id]: http(),
    [bscTestnet.id]: http(),
    [mainnet.id]: http(),
    [polygon.id]: http(),
  },

  ssr: false,
});
