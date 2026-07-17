import { pool } from "../database/db";

// 🔥 FULL COLLECTION PAGE

export async function getCollectionFull(contract: string) {
  const c = contract.toLowerCase();

  const { rows } = await pool.query(
    `
    WITH collection AS (
      SELECT *
      FROM collections
      WHERE contract_address = $1
    ),

    stats AS (
      SELECT
        MIN(l.price) FILTER (WHERE l.status='ACTIVE') AS floor_price,
        COUNT(DISTINCT o.owner_address) AS total_owners,
        COUNT(DISTINCT t.token_id) AS total_items,
        COALESCE(SUM(s.price), 0) AS total_volume
      FROM tokens t
      LEFT JOIN owners o
        ON o.contract_address = t.contract_address
       AND o.token_id = t.token_id
      LEFT JOIN listings l
        ON l.contract_address = t.contract_address
       AND l.token_id = t.token_id
      LEFT JOIN sales s
        ON s.contract_address = t.contract_address
       AND s.token_id = t.token_id
      WHERE t.contract_address = $1
    ),

    listings AS (
      SELECT *
      FROM listings
      WHERE contract_address = $1
        AND status = 'ACTIVE'
      ORDER BY price ASC
      LIMIT 50
    ),

    nfts AS (
      SELECT 
        t.contract_address,
        t.token_id,
        t.uri,
        o.owner_address
      FROM tokens t
      LEFT JOIN owners o
        ON o.contract_address = t.contract_address
       AND o.token_id = t.token_id
      WHERE t.contract_address = $1
      ORDER BY t.token_id DESC
      LIMIT 50
    ),

    activity AS (
      SELECT *
      FROM activities
      WHERE contract_address = $1
      ORDER BY block_number DESC, log_index DESC
      LIMIT 50
    )

    SELECT
      (SELECT row_to_json(collection) FROM collection) AS collection,
      (SELECT row_to_json(stats) FROM stats) AS stats,
      (SELECT json_agg(listings) FROM listings) AS listings,
      (SELECT json_agg(nfts) FROM nfts) AS nfts,
      (SELECT json_agg(activity) FROM activity) AS activity
    `,
    [c]
  );

  const data = rows[0] || {};

  return {
    collection: data.collection || null,
    stats: data.stats || {},
    listings: data.listings || [],
    nfts: data.nfts || [],
    activity: data.activity || [],
  };
}