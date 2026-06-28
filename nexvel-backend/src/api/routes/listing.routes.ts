import express from "express"
import {
  fetchListings,
  fetchListing,
  fetchUserListings,
  cancelListingController
} from "../controllers/listing.controller"

import { requireAuth } from "../middleware/auth"

const router = express.Router()

// 🔥 Get all active listings
router.get("/", fetchListings)

// 🔍 Get specific listing
router.get("/:contract/:tokenId", fetchListing)

// 👤 Get user listings
router.get("/user/:address", fetchUserListings)

// ❌ Cancel listing (protected)
router.post("/cancel", requireAuth, cancelListingController)

export default router