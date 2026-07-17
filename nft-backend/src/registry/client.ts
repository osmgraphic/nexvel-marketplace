import { getContract } from "viem";

import { client } from "../blockchain/client";
import { env } from "../config/env";

import RegistryAbi from "../abi/MarketplaceAddressRegistry";

export const registry = getContract({
  address: env.REGISTRY_ADDRESS,
  abi: RegistryAbi,
  client,
});