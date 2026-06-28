import { pool } from "../database/db";

// =======================================
// 🎨 SINGLE NFT
// =======================================

export async function getNFT(contract: string, tokenId: string) {
  const { rows } = await pool.query(
    `
    SELECT
      t.contract_address,
      t.token_id,
      t.metadata_uri,
      t.creator,
      t.royalty_bps,
      t.royalty_receiver,
      o.owner_address,
      l.price,
      l.status
    FROM tokens t
    LEFT JOIN owners o
      ON o.contract_address = t.contract_address
     AND o.token_id = t.token_id
    LEFT JOIN listings l
      ON l.contract_address = t.contract_address
     AND l.token_id = t.token_id
     AND l.status = 'ACTIVE'
    WHERE t.contract_address = $1
      AND t.token_id = $2
    LIMIT 1
    `,
    [contract, tokenId]
  );

  return rows[0] ?? null;
}

// =======================================
// 👤 USER NFTs
// =======================================

export async function getUserNFTs(address: string, limit: number, offset: number) {
  const result = await pool.query(
    `
    SELECT o.contract_address, o.token_id, t.uri
    FROM owners o
    LEFT JOIN tokens t
      ON o.contract_address = t.contract_address
      AND o.token_id = t.token_id
    WHERE o.owner_address = $1
    ORDER BY o.block_number DESC
    LIMIT $2 OFFSET $3
    `,
    [address, limit, offset]
  );

  return result.rows;
}

// =======================================
// 📦 COLLECTION NFTs
// =======================================

export async function getCollectionNFTs(contract: string, limit: number, offset: number) {
  const result = await pool.query(
    `
    SELECT t.contract_address, t.token_id, t.uri, o.owner_address
    FROM tokens t
    LEFT JOIN owners o
      ON t.contract_address = o.contract_address
      AND t.token_id = o.token_id
    WHERE t.contract_address = $1
    ORDER BY t.token_id DESC
    LIMIT $2 OFFSET $3
    `,
    [contract, limit, offset]
  );

  return result.rows;
}

// =======================================
// 🔥 FULL NFT DETAILS (MAIN ENDPOINT)
// =======================================

export async function getNFTFull(contract: string, tokenId: string) {
  // single roundtrip: details + last 20 activities + last 10 sales
  const { rows } = await pool.query(
    `
    WITH nft AS (
      SELECT
        t.contract_address,
        t.token_id,
        t.metadata_uri,
        t.creator,
        t.royalty_bps,
        t.royalty_receiver,
        o.owner_address,
        l.price,
        l.status
      FROM tokens t
      LEFT JOIN owners o
        ON o.contract_address = t.contract_address
       AND o.token_id = t.token_id
      LEFT JOIN listings l
        ON l.contract_address = t.contract_address
       AND l.token_id = t.token_id
       AND l.status = 'ACTIVE'
      WHERE t.contract_address = $1
        AND t.token_id = $2
      LIMIT 1
    ),
    acts AS (
      SELECT
        event_type, from_address, to_address, price,
        tx_hash, block_number, log_index
      FROM activities
      WHERE contract_address = $1 AND token_id = $2
      ORDER BY block_number DESC
      LIMIT 20
    ),
    sales AS (
      SELECT buyer, seller, price, tx_hash, created_at
      FROM sales
      WHERE contract_address = $1 AND token_id = $2
      ORDER BY created_at DESC
      LIMIT 10
    )
    SELECT
      (SELECT row_to_json(nft) FROM nft)          AS nft,
      (SELECT json_agg(acts) FROM acts)          AS activities,
      (SELECT json_agg(sales) FROM sales)        AS sales
    `,
    [contract, tokenId]
  );

  return rows[0] ?? { nft: null, activities: [], sales: [] };
}