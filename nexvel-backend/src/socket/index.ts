import { Server } from "socket.io";
import { Server as HttpServer } from "http";

import { rooms } from "./rooms";

let io: Server | null = null;

export function initSocket(server: HttpServer) {
  io = new Server(server, {
    cors: {
      origin: "*",
    },
  });

  io.on("connection", (socket) => {
      console.log("🔌 Client connected:", socket.id);
  
      socket.on("joinUser", (address: string) => {
    if (typeof address !== "string") return;
  
    socket.join(rooms.user(address));
  });
  
  socket.on("joinCollection", (contract: string) => {
    if (typeof contract !== "string") return;
  
    socket.join(rooms.collection(contract));
  });
  
  socket.on("joinMarketplace", () => {
    socket.join(rooms.marketplace());
  });
  
  socket.on("joinLaunchpad", () => {
    socket.join(rooms.launchpad());
  });

    socket.on("disconnect", () => {
      console.log("❌ Client disconnected:", socket.id);
    });
  });
}

export function getIO(): Server | null {
  return io;
}
