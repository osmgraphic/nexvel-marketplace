import { pool } from "../database/db";

// 🔥 Get all active listings
export async function getActiveListings(
  limit = 20,
  offset = 0
) {
  const { rows } = await pool.query(
    `
    SELECT
      l.contract_address,
      l.token_id,
      l.price,
      l.seller,
      l.block_number,
      t.metadata_uri,
      o.owner_address
    FROM listings l
    JOIN tokens t
      ON t.contract_address = l.contract_address
     AND t.token_id = l.token_id
    LEFT JOIN owners o
      ON o.contract_address = l.contract_address
     AND o.token_id = l.token_id
    WHERE l.status = 'ACTIVE'
    ORDER BY l.block_number DESC
    LIMIT $1 OFFSET $2
    `,
    [limit, offset]
  );

  return rows;
}

// 🔍 Get listing by token
export async function getListing(contract: string, tokenId: string) {
  const result = await pool.query(
    `
    SELECT *
    FROM listings
    WHERE contract_address = $1
      AND token_id = $2
      AND status = 'ACTIVE'
    `,
    [contract.toLowerCase(), tokenId]
  );

  return result.rows[0];
}

// 👤 Get user listings
export async function getUserListings(address: string) {
  const result = await pool.query(
    `
    SELECT *
    FROM listings
    WHERE seller = $1
    ORDER BY created_at DESC
    `,
    [address.toLowerCase()]
  );

  return result.rows;
}

// ❌ Cancel listing
export async function cancelListing(
  contract: string,
  tokenId: string,
  seller: string
) {
  await pool.query(
    `
    UPDATE listings
    SET
      status = 'CANCELLED',
      updated_at = NOW()
    WHERE contract_address = $1
      AND token_id = $2
      AND seller = $3
      AND status = 'ACTIVE'
    `,
    [contract.toLowerCase(), tokenId, seller.toLowerCase()]
  );
}