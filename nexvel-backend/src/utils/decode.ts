import { Interface } from "ethers";
import { CONTRACTS } from "../config/Contracts.Config";

const INTERFACES_BY_ADDRESS: Record<string, Interface> = {};

// 🔥 Build interface map
for (const contract of CONTRACTS) {
  if (contract.address) {
    INTERFACES_BY_ADDRESS[contract.address.toLowerCase()] =
      new Interface(contract.abi);
  }
}

export function decodeLog(log: any) {
  const iface = INTERFACES_BY_ADDRESS[log.address.toLowerCase()];
  if (!iface) return null;

  try {
    const parsed = iface.parseLog(log);
    if (!parsed) return null;

    return {
      contract: log.address.toLowerCase(),
      eventName: parsed.name,
      args: parsed.args,
    };
  } catch {
    return null;
  }
}