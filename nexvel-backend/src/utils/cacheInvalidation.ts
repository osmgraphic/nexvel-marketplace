import { redis } from "./redis";

export async function invalidateNFT(contract: string, tokenId: string) {
  const key = `${contract}:${tokenId}`;

  const pipe = redis.pipeline();
  pipe.del(`nft:${key}`);
  pipe.del(`nft:full:${key}`);
  pipe.del(`collection:full:${contract}`);
  pipe.del(`listings:${contract}`);
  await pipe.exec();
}

export async function invalidateUser(address: string) {
  const pipe = redis.pipeline();
  pipe.del(`user:portfolio:${address}`);
  pipe.del(`owner:${address}`);
  await pipe.exec();
}

export async function invalidateListings() {
  await redis.del("listings:all");
}