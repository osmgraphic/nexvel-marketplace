import { pool } from "../../database/db";

// 🔥 USER PORTFOLIO (ADVANCED)

export async function getUserPortfolio(address: string) {
  const a = address.toLowerCase();

  const { rows } = await pool.query(
    `
    WITH nfts AS (
      SELECT
        o.contract_address,
        o.token_id,
        t.uri
      FROM owners o
      LEFT JOIN tokens t
        ON t.contract_address = o.contract_address
       AND t.token_id = o.token_id
      WHERE o.owner_address = $1
      LIMIT 200
    ),

    collections AS (
      SELECT
        o.contract_address,
        COUNT(*)::int as count
      FROM owners o
      WHERE o.owner_address = $1
      GROUP BY o.contract_address
    ),

    activity AS (
      SELECT *
      FROM activities
      WHERE from_address = $1 OR to_address = $1
      ORDER BY block_number DESC, log_index DESC
      LIMIT 20
    ),

    estimated AS (
      SELECT
        COALESCE(SUM(l.price), 0) AS total_value
      FROM owners o
      LEFT JOIN listings l
        ON l.contract_address = o.contract_address
       AND l.token_id = o.token_id
       AND l.status = 'ACTIVE'
      WHERE o.owner_address = $1
    )

    SELECT
      (SELECT json_agg(nfts) FROM nfts) AS nfts,
      (SELECT json_agg(collections) FROM collections) AS collections,
      (SELECT json_agg(activity) FROM activity) AS activity,
      (SELECT total_value FROM estimated) AS estimated_value,
      (SELECT COUNT(*) FROM nfts) AS total_nfts,
      (SELECT COUNT(*) FROM collections) AS total_collections
    `,
    [a]
  );

  const data = rows[0];

  return {
    summary: {
      totalNFTs: data.total_nfts || 0,
      totalCollections: data.total_collections || 0,
      estimatedValue: data.estimated_value || "0"
    },
    collections: data.collections || [],
    nfts: data.nfts || [],
    activity: data.activity || []
  };
}

// 👤 Get user NFTs
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

// 📊 Get user activity
export async function getUserActivity(address: string, limit: number, offset: number) {
  const result = await pool.query(
    `
    SELECT *
    FROM activities
    WHERE from_address=$1 OR to_address=$1
    ORDER BY block_number DESC
    LIMIT $2 OFFSET $3
    `,
    [address, limit, offset]
  );

  return result.rows;
}