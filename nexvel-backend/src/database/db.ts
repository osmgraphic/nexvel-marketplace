import { Pool, PoolClient, QueryResult, QueryResultRow } from "pg";
import { env } from "../config/env";
import { logger } from "../utils/logger";


// ===============================
// 🔧 POOL CONFIG
// ===============================
export const pool = new Pool({
  connectionString: env.DB,

  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,

  ssl:
    env.NODE_ENV === "production"
      ? { rejectUnauthorized: false }
      : false,
});

// ===============================
// 🔌 EVENTS
// ===============================
pool.on("connect", () => {
  logger.info("🟢 PostgreSQL connected");
});

pool.on("error", (err: Error) => {
  logger.error({ err }, "❌ PostgreSQL error");
});

// ===============================
// 🧪 TEST DB CONNECTION
// ===============================
export async function testDbConnection(): Promise<boolean> {
  try {
    const res = await pool.query("SELECT NOW()");
    logger.info({ result: res.rows[0] }, "✅ DB Connected");
    return true;
  } catch (err: unknown) {
    logger.error({ err }, "❌ DB Connection Failed");
    return false;
  }
}

// ===============================
// ⚡ QUERY HELPER
// ===============================
export async function query<T extends QueryResultRow = QueryResultRow>(
  text: string,
  params?: unknown[],
  options?: { timeout?: number }
): Promise<QueryResult<T>> {
  const start = Date.now();

  const client = await pool.connect();

  try {
    // 🔥 apply timeout safely
    if (options?.timeout) {
      await client.query(`SET LOCAL statement_timeout = ${options.timeout}`);
    }

    const res = await client.query<T>(text, params as any[]);

    const duration = Date.now() - start;

    if (duration > 200) {
      logger.warn({ text, duration }, "🐢 Slow query");
    }

    return res;

  } catch (err: unknown) {
    logger.error({ err, text, params }, "❌ Query error");
    throw err;

  } finally {
    client.release();
  }
}
// ===============================
// 🔄 TRANSACTION HELPER
// ===============================
export async function withTransaction<T>(
  fn: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const result = await fn(client);

    await client.query("COMMIT");
    return result;

  } catch (err: unknown) {
    await client.query("ROLLBACK");
    logger.error({ err }, "❌ Transaction failed");
    throw err;

  } finally {
    client.release();
  }
}

// ===============================
// ❤️ HEALTH CHECK
// ===============================
export async function checkDBHealth(): Promise<boolean> {
  try {
    await pool.query("SELECT 1");
    return true;
  } catch {
    return false;
  }
}

// ===============================
// 🛑 GRACEFUL SHUTDOWN
// ===============================
async function shutdown(): Promise<void> {
  try {
    logger.info("🛑 Closing PostgreSQL pool...");
    await pool.end();
    process.exit(0);
  } catch (err: unknown) {
    logger.error({ err }, "❌ Error during DB shutdown");
    process.exit(1);
  }
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);