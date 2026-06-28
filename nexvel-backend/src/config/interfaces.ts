import { Interface } from "ethers";
import { CONTRACTS } from "./Contracts.Config";

/**
 * Address → Interface map
 */
export const INTERFACES_BY_ADDRESS: Record<string, Interface> = {};

/**
 * Topic → Interface map (for fast log decoding)
 */
export const INTERFACES_BY_TOPIC: Record<string, Interface> = {};

/**
 * Initialize mappings
 */
for (const contract of CONTRACTS) {
  if (!contract.address) continue;

  const normalizedAddress = contract.address.toLowerCase();
  const iface = new Interface(contract.abi);

  // Address mapping
  INTERFACES_BY_ADDRESS[normalizedAddress] = iface;

  // Topic mapping (event signature → interface)
  for (const fragment of Object.values(iface.fragments)) {
    if (fragment.type !== "event") continue;

    const eventFragment = iface.getEvent((fragment as any).name);
    if (!eventFragment) continue;

    const topic = eventFragment.topicHash;

    INTERFACES_BY_TOPIC[topic] = iface;
  }
}