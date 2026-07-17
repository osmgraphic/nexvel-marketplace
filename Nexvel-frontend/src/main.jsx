import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import { anvil } from "./chains/anvil";
import { http } from "viem";

import "@rainbow-me/rainbowkit/styles.css";

import {
  RainbowKitProvider,
  getDefaultConfig
} from "@rainbow-me/rainbowkit";

import { WagmiProvider } from "wagmi";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { mainnet, polygon, sepolia, } from "wagmi/chains";

const config = getDefaultConfig({
  appName: "Nexvel DApp",
  projectId: import.meta.env.VITE_PROJECT_ID,  // must exist
  chains: [anvil], // use your chain
  transports: {
    [anvil.id]: http(import.meta.env.VITE_RPC_URL), // RPC from .env
  },
});

const queryClient = new QueryClient();

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <App />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  </React.StrictMode>
);
