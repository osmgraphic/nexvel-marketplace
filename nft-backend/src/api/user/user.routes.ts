import { Router } from "express"
import {
  fetchUserNFTs,
  fetchUserActivity
} from "./user.controller";
import { fetchUserPortfolio } from "./user.controller";

const router = Router()

router.get("/:wallet/portfolio", fetchUserPortfolio);
router.get("/:wallet/nfts", fetchUserNFTs)
router.get("/:wallet/activity", fetchUserActivity)

export default router