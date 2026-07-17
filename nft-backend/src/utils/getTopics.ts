import { Interface, EventFragment } from "ethers";

export function extractTopics(abi: any[]) {
  const iface = new Interface(abi);

  const topics: Record<string, string> = {};

  for (const fragment of iface.fragments) {
    if (fragment.type === "event") {
      const eventFragment = fragment as EventFragment;
      const topic = eventFragment.topicHash;
      topics[eventFragment.format()] = topic;
    }
  }

  return topics;
}