import http from "http";

import app from "./api/server";
import { bootstrap } from "./bootstrap";
import { env } from "./config/env";
import { initSocket } from "./socket";

const server = http.createServer(app);

async function start() {
  try {
    // Initialize entire application
    await bootstrap();

    // Attach Socket.IO
    initSocket(server);

    server.listen(env.PORT, () => {
      console.log(`🚀 Nexvel Backend running on port ${env.PORT}`);
    });

  } catch (error) {
    console.error("❌ Application startup failed");
    console.error(error);
    process.exit(1);
  }
}

start();