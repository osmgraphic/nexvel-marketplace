import express from "express"
import {
  fetchNFT,
  fetchUserNFTs,
  fetchCollectionNFTs
} from "../controllers/nft.controller"
import { fetchNFTFull } from "../controllers/nft.controller";

const router = express.Router()

router.get("/:contract/:tokenId/full", fetchNFTFull);

// 🎨 Single NFT
router.get("/:contract/:tokenId", fetchNFT)

// 👤 User NFTs
router.get("/user/:address", fetchUserNFTs)

// 📦 Collection NFTs
router.get("/collection/:contract", fetchCollectionNFTs)

export default router