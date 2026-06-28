import http from "http";
import app from "./api/server";

import { initSocket } from "./utils/socket";
import { testDbConnection } from "./database/db";

const PORT = process.env.PORT || 4000;

// ===============================
// 📡 CREATE SERVER
// ===============================
const server = http.createServer(app);

// ===============================
// 🔌 SOCKET
// ===============================
initSocket(server);

// ===============================
// 🚀 START
// ===============================
async function start() {
  const ok = await testDbConnection();

  if (!ok) {
    console.error("❌ DB failed. Exit.");
    process.exit(1);
  }
  

  server.listen(PORT, () => {
    console.log(`🔥 Server running on ${PORT}`);
  });
}

start();