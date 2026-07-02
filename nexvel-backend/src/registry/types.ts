export interface RegistryMetadata {
  protocol: string;
  version: number;
  chainId: number;
  initialized: boolean;
}

export interface RegistryAddresses {
  security: `0x${string}`;
  marketplace: `0x${string}`;
  launchpad: `0x${string}`;
  erc1155: `0x${string}`;
  nftFactory: `0x${string}`;
}