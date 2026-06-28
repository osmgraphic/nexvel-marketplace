import { pool } from "../database/db";

// 🔥 Get all active listings
export async function getActiveListings(params: {
  contract?: string;
  cursorBlock?: number;   // for pagination
  limit?: number;
}) {
  const { contract, cursorBlock, limit = 20 } = params;

  const values: any[] = [];
  let i = 1;

  let where = `l.status = 'ACTIVE'`;

  if (contract) {
    where += ` AND l.contract_address = $${i++}`;
    values.push(contract);
  }

  if (cursorBlock) {
    where += ` AND l.block_number < $${i++}`;
    values.push(cursorBlock);
  }

  values.push(limit);

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
    WHERE ${where}
    ORDER BY l.block_number DESC
    LIMIT $${i}
    `,
    values
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
  )

  return result.rows[0]
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
  )

  return result.rows
}

// ❌ Cancel listing (off-chain support)
export async function cancelListing(
  contract: string,
  tokenId: string,
  seller: string
) {
  await pool.query(
    `
    UPDATE listings
    SET status = 'CANCELLED',
        updated_at = NOW()
    WHERE contract_address = $1
    AND token_id = $2
    AND seller = $3
    AND status = 'ACTIVE'
    `,
    [contract.toLowerCase(), tokenId, seller.toLowerCase()]
  )
}