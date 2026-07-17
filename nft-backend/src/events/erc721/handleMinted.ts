import { storeActivity } from "../activity/activity";
import { PoolClient } from "pg";
import { createNotification } from "../../api/notifications/notification.service";
import { eventBus } from "../../utils/eventBus";

// 🔧 helper
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleERC721Minted(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // 🔥 guards
    if (!args || !meta) {
      console.warn("⚠️ Mint skipped: missing args/meta");
      return;
    }

    const { to, tokenId, uri, creator } = args;

    if (!to || !tokenId) {
      console.warn("⚠️ Mint skipped: invalid data");
      return;
    }

    const contract = normalize(meta.address)!;
    const txHash = meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    const tokenIdStr = tokenId.toString();
    const toAddr = normalize(to)!;
    const creatorAddr = normalize(creator) || toAddr;
    const tokenURI = uri || "";

    // ===============================
    // 🪙 TOKEN UPSERT
    // ===============================
    await client.query(
      `
      INSERT INTO tokens (contract_address, token_id, creator, uri)
      VALUES ($1,$2,$3,$4)
      ON CONFLICT (contract_address, token_id)
      DO UPDATE SET uri = EXCLUDED.uri
      WHERE tokens.uri IS DISTINCT FROM EXCLUDED.uri
      `,
      [contract, tokenIdStr, creatorAddr, tokenURI]
    );

    // ===============================
    // 👤 OWNER UPSERT
    // ===============================
    await client.query(
      `
      INSERT INTO owners (contract_address, token_id, owner_address)
      VALUES ($1,$2,$3)
      ON CONFLICT (contract_address, token_id)
      DO UPDATE SET owner_address = EXCLUDED.owner_address
      WHERE owners.owner_address IS DISTINCT FROM EXCLUDED.owner_address
      `,
      [contract, tokenIdStr, toAddr]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "MINT",
      contract,
      tokenIdStr,
      creatorAddr,
      toAddr,
      "0",
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🔔 NOTIFICATION (DB only)
    // ===============================
    await createNotification(
      toAddr,
      "MINT",
      "You received a new NFT",
      { contract, tokenId: tokenIdStr },
      txHash
    );

    // ===============================
    // 🚀 EVENT BUS (CRITICAL)
    // ===============================
    // 👉 This replaces cache + websocket logic
    eventBus.emit("mint", {
      contract,
      tokenId: tokenIdStr,
      to: toAddr,
      creator: creatorAddr,
      txHash,
      blockNumber,
    });

  } catch (err) {
    console.error("❌ ERC721 Mint error:", {
      contract: meta?.address,
      tokenId: args?.tokenId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}