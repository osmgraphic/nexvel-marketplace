import { Server } from "socket.io";

let io: Server;

export function initSocket(server: any) {
  io = new Server(server, {
    cors: { origin: "*" },
    pingTimeout: 20000,
    pingInterval: 25000,
  });

  io.on("connection", (socket) => {
    console.log("🔌 Connected:", socket.id);

    socket.on("join:user", (addr) => {
      socket.join(`user:${addr}`);
    });

    socket.on("join:collection", (contract) => {
      socket.join(`collection:${contract}`);
    });
  });
}

export function broadcast(event: string, data: any) {
  io?.emit(event, data);
}

export function broadcastToUser(addr: string, event: string, data: any) {
  io?.to(`user:${addr}`).emit(event, data);
}

export function broadcastToCollection(contract: string, event: string, data: any) {
  io?.to(`collection:${contract}`).emit(event, data);
}