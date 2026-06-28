import NexvelERC721ImplAbi from "../abi/NexvelERC721Impl";
import NexvelERC721AAbi from "../abi/NexvelERC721A";
import NexvelERC1155UpgradeableAbi from "../abi/NexvelERC1155Upgradeable";
import NexvelLaunchpadAbi from "../abi/NexvelLaunchpad";
import NexvelMarketplaceV3Abi from "../abi/NexvelMarketplaceV3";
import NexvelNFTFactoryAbi from "../abi/NexvelNFTFactory";

import { env } from "./env";

  export type ContractConfig = {
    name: string;
    address?: string;
    abi: any;
  };

  export const CONTRACTS: ContractConfig[] = [
    {
      name: "NexvelERC721Impl",
      address: env.ERC721_IMPL_ADDRESS,
      abi: NexvelERC721ImplAbi,
    },
    {
      name: "NexvelERC721A",
      address: env.ERC721A_IMPL_ADDRESS,
      abi: NexvelERC721AAbi,
    },
    {
      name: "NexvelERC1155Upgradeable",
      address: env.ERC1155_ADDRESS,
      abi: NexvelERC1155UpgradeableAbi,
    },
    {
      name: "NexvelLaunchpad",
      address: env.LAUNCHPAD_ADDRESS,
      abi: NexvelLaunchpadAbi,
    },
    {
      name: "NexvelMarketplaceV3",
      address: env.MARKETPLACE_ADDRESS,
      abi: NexvelMarketplaceV3Abi,
    },
    {
      name: "NexvelNFTFactory",
      address: env.FACTORY_ADDRESS,
      abi: NexvelNFTFactoryAbi,
    },
  ];