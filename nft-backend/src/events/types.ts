import { PoolClient } from "pg";

export interface EventMeta {
  transactionHash: string;
  blockNumber: number;
  logIndex: number;
  address: string;
}

export interface EventContext<T = unknown> {
  args: T;
  meta: EventMeta;
  client: PoolClient;
}