import { storeActivity } from "../activity/activity";
import { PoolClient } from "pg";
import { eventBus } from "../../utils/eventBus";

const ZERO = "0x0000000000000000000000000000000000000000";

export async function handleERC721Transfer(log: any, blockNumber: number, client: PoolClient) {
  try {
    const contract = log.address.toLowerCase();
    const from = ("0x" + log.topics[1].slice(26)).toLowerCase();
    const to = ("0x" + log.topics[2].slice(26)).toLowerCase();
    const tokenId = BigInt(log.topics[3]).toString();
    const txHash = log.transactionHash;

    await client.query("BEGIN");

    await client.query(
      `
      INSERT INTO transfers
      (contract_address, token_id, from_address, to_address, tx_hash, block_number)
      VALUES ($1,$2,$3,$4,$5,$6)
      ON CONFLICT (tx_hash, token_id) DO NOTHING
      `,
      [contract, tokenId, from, to, txHash, blockNumber]
    );

    if (to === ZERO) {
      await client.query(
        `DELETE FROM owners WHERE contract_address=$1 AND token_id=$2`,
        [contract, tokenId]
      );
    } else {
      await client.query(
        `
        INSERT INTO owners (contract_address, token_id, owner_address)
        VALUES ($1,$2,$3)
        ON CONFLICT (contract_address, token_id)
        DO UPDATE SET owner_address = EXCLUDED.owner_address
        `,
        [contract, tokenId, to]
      );
    }

    await storeActivity(
      "TRANSFER",
      contract,
      tokenId,
      from,
      to,
      null,
      txHash,
      blockNumber,
      log.logIndex,
      client
    );

    await client.query("COMMIT");

    // 🔥 EVENT
    eventBus.emit("transfer", {
      contract,
      tokenId,
      from,
      to,
      txHash,
      blockNumber
    });

  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}