import { Router } from "express";

import {
  fetchUserNFTs,
  fetchUserActivity,
} from "../controllers/user.controller";

const router = Router();

router.get("/:wallet/nfts", fetchUserNFTs);

router.get("/:wallet/activity", fetchUserActivity);

export default router;