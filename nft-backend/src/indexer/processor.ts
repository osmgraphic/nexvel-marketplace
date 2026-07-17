import { client as blockchainClient } from "../blockchain/client";
import { pool } from "../database/db";
import { routeLogs } from "./router";

import { getContracts } from "../contracts/discovery";

export async function processBlock(blockNumber: number) {
  console.debug(`📦 Processing block ${blockNumber}`);

  const dbClient = await pool.connect();

  try {
    const contracts = getContracts();

    const addresses = [
      contracts.marketplace,
      contracts.launchpad,
      contracts.erc1155,
      contracts.nftFactory,
      contracts.security,
    ].filter(
      (addr) =>
        addr !== "0x0000000000000000000000000000000000000000"
    );

    if (addresses.length === 0) {
      return;
    }

    const logs = await blockchainClient.getLogs({
      fromBlock: BigInt(blockNumber),
      toBlock: BigInt(blockNumber),
      address: addresses,
    });

    if (logs.length === 0) {
      return;
    }

    await routeLogs(logs, dbClient);
  } catch (err) {
    console.error(`❌ Error processing block ${blockNumber}`, err);
    throw err;
  } finally {
    dbClient.release();
  }
}