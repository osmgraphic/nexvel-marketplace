import { Server } from "socket.io";

let io: Server;

export function initSocket(server: any) {
  io = new Server(server, {
    cors: {
      origin: "*",
    },
  });

  io.on("connection", (socket) => {
    console.log("🔌 Client connected:", socket.id);

    // 👤 Join user room
    socket.on("joinUser", (address: string) => {
      socket.join(`user:${address.toLowerCase()}`);
    });

    // 📦 Join collection room
    socket.on("joinCollection", (contract: string) => {
      socket.join(`collection:${contract.toLowerCase()}`);
    });

    socket.on("disconnect", () => {
      console.log("❌ Client disconnected:", socket.id);
    });
  });
}

export function getIO() {
  if (!io) throw new Error("Socket not initialized");
  return io;
}