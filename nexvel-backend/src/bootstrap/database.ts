import { testDbConnection } from "../database/db";
import { container } from "../core/container";

export async function initDatabase() {
  const ok = await testDbConnection();

  if (!ok) {
    throw new Error("Database initialization failed.");
  }

  container.database = true;

  console.log("✅ Database Initialized");
}