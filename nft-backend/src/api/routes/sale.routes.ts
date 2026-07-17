import express from "express"
import {
  fetchSales,
  fetchNFTSales,
  fetchUserPurchases,
  fetchVolume
} from "../controllers/sale.controller"

const router = express.Router()

router.get("/", fetchSales);

router.get("/volume", fetchVolume);

router.get("/user/:address", fetchUserPurchases);

router.get("/:contract/:tokenId", fetchNFTSales);

export default router