import { z } from "zod";

export const addressSchema = z.string().length(42);

export const nftSchema = z.object({
  contract: addressSchema,
  tokenId: z.string(),
});