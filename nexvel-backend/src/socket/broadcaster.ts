import { getIO } from "./index";
import { rooms } from "./rooms";

export function broadcast(event: string, data: unknown) {
  getIO()?.emit(event, data);
}

export function broadcastToUser(
  address: string,
  event: string,
  data: unknown
) {
  getIO()?.to(rooms.user(address)).emit(event, data);
}

export function broadcastToCollection(
  contract: string,
  event: string,
  data: unknown
) {
  getIO()?.to(rooms.collection(contract)).emit(event, data);
}

export function broadcastMarketplace(
  event: string,
  data: unknown
) {
  getIO()?.to(rooms.marketplace()).emit(event, data);
}

export function broadcastLaunchpad(
  event: string,
  data: unknown
) {
  getIO()?.to(rooms.launchpad()).emit(event, data);
}

export function notifyUser(
  address: string,
  payload: unknown
) {
  getIO()
    ?.to(rooms.user(address))
    .emit("notification", payload);
}