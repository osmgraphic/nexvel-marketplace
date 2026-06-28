import { Router } from "express";
import {
  fetchActivity,
  fetchNFTActivity
} from "../controllers/activity.controller";

const router = Router();

// 🔥 Global activity
router.get("/", fetchActivity);

// 🔥 NFT activity
router.get("/:contract/:tokenId", fetchNFTActivity);

export default router;