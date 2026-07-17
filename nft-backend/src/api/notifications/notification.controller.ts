import { addressSchema } from "../utils/validation";
import {
  getUserNotifications,
  getUnreadCount,
  markAllRead
} from "./notification.service";

// 🔥 GET /notifications/:address
export async function fetchNotifications(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.address);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid address" });
    }

    const address = parsed.data;

    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const offset = Number(req.query.offset) || 0;

    const data = await getUserNotifications(address, limit, offset);

    res.json(data);

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to fetch notifications" });
  }
}

// 🔥 GET unread count
export async function fetchUnread(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.address);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid address" });
    }

    const count = await getUnreadCount(parsed.data);

    res.json({ unread: count });

  } catch (err) {
    res.status(500).json({ error: "Failed" });
  }
}

// 🔥 POST mark read
export async function markRead(req: any, res: any) {
  try {
    const parsed = addressSchema.safeParse(req.params.address);

    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid address" });
    }

    await markAllRead(parsed.data);

    res.json({ success: true });

  } catch (err) {
    res.status(500).json({ error: "Failed" });
  }
}