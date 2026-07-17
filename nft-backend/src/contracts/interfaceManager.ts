import { Interface } from "ethers";

import { CONTRACT_ABIS } from "./abi";
import { getContracts } from "./discovery";

const interfacesByAddress = new Map<string, Interface>();
const interfacesByTopic = new Map<string, Interface>();

let initialized = false;

export function initializeInterfaces() {
  if (initialized) return;

  const contracts = getContracts();

  const mapping = {
    [contracts.marketplace.toLowerCase()]: CONTRACT_ABIS.marketplace,
    [contracts.launchpad.toLowerCase()]: CONTRACT_ABIS.launchpad,
    [contracts.erc1155.toLowerCase()]: CONTRACT_ABIS.erc1155,
    [contracts.nftFactory.toLowerCase()]: CONTRACT_ABIS.nftFactory,
    [contracts.security.toLowerCase()]: CONTRACT_ABIS.security,
  };

  for (const [address, abi] of Object.entries(mapping)) {
    const iface = new Interface(abi);

    interfacesByAddress.set(address, iface);

    iface.forEachEvent((event) => {
      interfacesByTopic.set(event.topicHash, iface);
    });
  }

  initialized = true;

  console.log("✅ Interface Manager Initialized");
}

export function getInterfaceByAddress(address: string) {
  return interfacesByAddress.get(address.toLowerCase());
}

export function getInterfaceByTopic(topic: string) {
  return interfacesByTopic.get(topic);
}

export function getAllInterfaces() {
  return interfacesByAddress;
}