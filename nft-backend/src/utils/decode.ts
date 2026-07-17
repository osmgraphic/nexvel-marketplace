import {
  getInterfaceByAddress,
  getInterfaceByTopic,
} from "../contracts/interfaceManager";

export function decodeLog(log: any) {
  const iface =
    getInterfaceByAddress(log.address) ??
    getInterfaceByTopic(log.topics[0]);

  if (!iface) {
    return null;
  }

  try {
    const parsed = iface.parseLog({
      topics: log.topics,
      data: log.data,
    });

    if (!parsed) {
      return null;
    }

    return {
      contract: log.address.toLowerCase(),
      eventName: parsed.name,
      args: parsed.args,
    };
  } catch {
    return null;
  }
}