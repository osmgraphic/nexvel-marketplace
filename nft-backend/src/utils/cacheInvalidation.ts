import { redis } from "./redis";

export async function invalidateNFT(
  contract: string,
  tokenId: string
) {
  const key = `${contract}:${tokenId}`;

  const pipe = redis.pipeline();

  pipe.del(`nft:${key}`);
  pipe.del(`nft:full:${key}`);
  pipe.del(`collection:full:${contract}`);

  const listingKeys = await redis.keys("listings:active:*");

  if (listingKeys.length > 0) {
    pipe.del(...listingKeys);
  }

  await pipe.exec();
}

export async function invalidateListings() {
  const keys = await redis.keys("listings:active:*");

  if (keys.length > 0) {
    await redis.del(...keys);
  }
}

export async function invalidateUser(address: string) {
  const pipe = redis.pipeline();

  pipe.del(`user:portfolio:${address.toLowerCase()}`);
  pipe.del(`owner:${address.toLowerCase()}`);

  await pipe.exec();
}