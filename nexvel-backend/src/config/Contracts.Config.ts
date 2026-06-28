import NexvelERC721ImplAbi from "../abi/NexvelERC721Impl";
import NexvelERC721AAbi from "../abi/NexvelERC721A";
import NexvelERC1155UpgradeableAbi from "../abi/NexvelERC1155Upgradeable";
import NexvelLaunchpadAbi from "../abi/NexvelLaunchpad";
import NexvelMarketplaceV3Abi from "../abi/NexvelMarketplaceV3";
import NexvelNFTFactoryAbi from "../abi/NexvelNFTFactory";

import dotenv from "dotenv";

  dotenv.config();

  export type ContractConfig = {
    name: string;
    address?: string;
    abi: any;
  };

  export const CONTRACTS: ContractConfig[] = [
    {
      name: "NexvelERC721Impl",
      address: process.env.ERC721_IMPL_ADDRESS,
      abi: NexvelERC721ImplAbi,
    },
    {
      name: "NexvelERC721A",
      address: process.env.ERC721A_IMPL_ADDRESS,
      abi: NexvelERC721AAbi,
    },
    {
      name: "NexvelERC1155Upgradeable",
      address: process.env.ERC1155_ADDRESS,
      abi: NexvelERC1155UpgradeableAbi,
    },
    {
      name: "NexvelLaunchpad",
      address: process.env.LAUNCHPAD_ADDRESS,
      abi: NexvelLaunchpadAbi,
    },
    {
      name: "NexvelMarketplaceV3",
      address: process.env.MARKETPLACE_ADDRESS,
      abi: NexvelMarketplaceV3Abi,
    },
    {
      name: "NexvelNFTFactory",
      address: process.env.FACTORY_ADDRESS,
      abi: NexvelNFTFactoryAbi,
    },
  ];