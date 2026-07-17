import { pool } from "../../database/db";

// 🔍 Search NFTs
export async function searchNFTs(query: string, limit: number) {
  const { rows } = await pool.query(
    `
    SELECT contract_address, token_id, metadata_uri
    FROM tokens
    WHERE metadata_uri ILIKE $1
    ORDER BY similarity(metadata_uri, $2) DESC
    LIMIT 50
    `,
    [`%${query}%`, query]
  );
  return rows;
}

// 📦 Search collections
export async function searchCollections(query: string, limit: number) {
  const { rows } = await pool.query(
    `
    SELECT contract_address, name
    FROM collections
    WHERE name ILIKE $1
    ORDER BY similarity(name, $2) DESC
    LIMIT 50
    `,
    [`%${query}%`, query]
  );
  return rows;
}

// 🛒 Search listings
export async function searchListings(query: string, limit: number) {
  const { rows } = await pool.query(
    `
    SELECT contract_address, token_id, price
    FROM listings
    WHERE contract_address ILIKE $1
      AND status = 'ACTIVE'
    LIMIT 50
    `,
    [`%${query}%`]
  );
  return rows;
}

// 🔥 Global search (combined)
export async function globalSearch(query: string, limit: number) {
  const [nfts, collections, listings] = await Promise.all([
    searchNFTs(query, limit),
    searchCollections(query, limit),
    searchListings(query, limit)
  ]);

  return { nfts, collections, listings };
}