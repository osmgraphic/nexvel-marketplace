import { redis } from "./redis";

export async function getOrSetCache<T>(
  key: string,
  ttlSeconds: number,
  fn: () => Promise<T>
): Promise<T> {
  const cached = await redis.get(key);
  if (cached) return JSON.parse(cached);

  const fresh = await fn();
  // don’t cache null/undefined accidentally
  if (fresh !== undefined) {
    await redis.set(key, JSON.stringify(fresh), "EX", ttlSeconds);
  }
  return fresh;
}

// optional: pattern invalidation helper
export async function delPattern(pattern: string) {
  const stream = redis.scanStream({ match: pattern, count: 100 });
  const pipeline = redis.pipeline();
  return new Promise<void>((resolve, reject) => {
    stream.on("data", (keys: string[]) => {
      if (keys.length) {
        keys.forEach((k) => pipeline.del(k));
      }
    });
    stream.on("end", async () => {
      await pipeline.exec();
      resolve();
    });
    stream.on("error", reject);
  });
}