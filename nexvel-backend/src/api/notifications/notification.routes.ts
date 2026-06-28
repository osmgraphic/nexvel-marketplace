import { Router } from "express";
import {
  fetchNotifications,
  fetchUnread,
  markRead
} from "./notification.controller";

const router = Router();

router.get("/:address", fetchNotifications);
router.get("/:address/unread", fetchUnread);
router.post("/:address/read", markRead);

export default router;