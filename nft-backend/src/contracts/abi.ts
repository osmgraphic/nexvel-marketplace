import MarketplaceAbi from "../abi/NexvelMarketplaceV3";
import LaunchpadAbi from "../abi/NexvelLaunchpad";
import ERC1155Abi from "../abi/NexvelERC1155Upgradeable";
import FactoryAbi from "../abi/NexvelNFTFactory";
import SecurityAbi from "../abi/NexvelSecurityUpgradeable";

export const CONTRACT_ABIS = {
  marketplace: MarketplaceAbi,
  launchpad: LaunchpadAbi,
  erc1155: ERC1155Abi,
  nftFactory: FactoryAbi,
  security: SecurityAbi,
} as const;