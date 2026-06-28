import { PoolClient } from "pg";
import { storeActivity } from "../activity/activity";
import { eventBus } from "../../utils/eventBus";

// 🔧 helpers
function normalize(addr?: string) {
  return addr ? addr.toLowerCase() : null;
}

export async function handleSaleCreated(
  args: any,
  meta: any,
  client: PoolClient
) {
  try {
    // ===============================
    // 🔥 GUARDS
    // ===============================
    if (!args || !meta) {
      console.warn("⚠️ SaleCreated skipped: missing args/meta");
      return;
    }

    const {
      saleId,
      creator,
      nft,
      tokenId,
      saleType,
      price,
      maxSupply,
      startTime,
      endTime,
    } = args;

    if (!saleId || !creator || !nft) {
      console.warn("⚠️ SaleCreated skipped: invalid data");
      return;
    }

    const saleIdStr = saleId.toString();
    const contract = normalize(nft)!;
    const creatorAddr = normalize(creator)!;
    const tokenIdStr = tokenId?.toString() || "0";

    const txHash = meta.txHash || meta.transactionHash;
    const blockNumber = Number(meta.blockNumber);
    const logIndex = meta.logIndex;

    const start = startTime ? new Date(Number(startTime) * 1000) : null;
    const end = endTime ? new Date(Number(endTime) * 1000) : null;

    // ===============================
    // 🚀 UPSERT SALE (idempotent)
    // ===============================
    await client.query(
      `
      INSERT INTO launchpad_sales
      (
        sale_id,
        creator,
        nft,
        token_id,
        sale_type,
        price,
        max_supply,
        sold,
        start_time,
        end_time,
        status
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,0,$8,$9,'ACTIVE')
      ON CONFLICT (sale_id)
      DO UPDATE SET
        price = EXCLUDED.price,
        max_supply = EXCLUDED.max_supply,
        start_time = EXCLUDED.start_time,
        end_time = EXCLUDED.end_time,
        status = 'ACTIVE'
      WHERE launchpad_sales.price IS DISTINCT FROM EXCLUDED.price
         OR launchpad_sales.max_supply IS DISTINCT FROM EXCLUDED.max_supply
         OR launchpad_sales.start_time IS DISTINCT FROM EXCLUDED.start_time
         OR launchpad_sales.end_time IS DISTINCT FROM EXCLUDED.end_time
         OR launchpad_sales.status IS DISTINCT FROM 'ACTIVE'
      `,
      [
        saleIdStr,
        creatorAddr,
        contract,
        tokenIdStr,
        saleType,
        price,
        maxSupply,
        start,
        end,
      ]
    );

    // ===============================
    // 📊 ACTIVITY
    // ===============================
    await storeActivity(
      "LAUNCHPAD_CREATE",
      contract,
      tokenIdStr,
      creatorAddr,
      creatorAddr,
      price?.toString() || null,
      txHash,
      blockNumber,
      logIndex,
      client
    );

    // ===============================
    // 🧹 Event
    // ===============================
    eventBus.emit("launchpad:created", {
      saleId,
      contract,
      creator,
      price,
    });

    console.log("🚀 Launchpad sale created:", saleIdStr);

  } catch (err) {
    console.error("❌ handleSaleCreated:", {
      saleId: args?.saleId,
      err
    });

    throw err; // 🔥 required for rollback
  }
}