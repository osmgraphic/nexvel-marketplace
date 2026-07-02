export function normalizeAddress(
  address?: string | null
): string | null {
  return address ? address.toLowerCase() : null;
}

export function normalizeTokenId(
  tokenId?: bigint | number | string | null
): string | null {
  return tokenId !== null && tokenId !== undefined
    ? tokenId.toString()
    : null;
}

export function normalizePrice(
  price?: bigint | number | string | null
): string | null {
  return price !== null && price !== undefined
    ? price.toString()
    : null;
}