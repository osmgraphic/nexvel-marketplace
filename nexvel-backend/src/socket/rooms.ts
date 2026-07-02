export const rooms = {
  user: (address: string) =>
    `user:${address.toLowerCase()}`,

  collection: (contract: string) =>
    `collection:${contract.toLowerCase()}`,

  marketplace: () => "marketplace",

  launchpad: () => "launchpad",

  activity: () => "activity",
};