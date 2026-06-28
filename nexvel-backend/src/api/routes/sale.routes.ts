import express from "express"
import {
  fetchSales,
  fetchNFTSales,
  fetchUserPurchases,
  fetchVolume
} from "../controllers/sale.controller"

const router = express.Router()

// 💰 All sales
router.get("/", fetchSales)

// 📊 NFT sales
router.get("/:contract/:tokenId", fetchNFTSales)

// 👤 User purchases
router.get("/user/:address", fetchUserPurchases)

// 📈 Total volume
router.get("/volume", fetchVolume)

export default router