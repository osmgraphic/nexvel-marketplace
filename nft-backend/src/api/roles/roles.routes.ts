import express from "express"
import { setRole, fetchRole } from "./roles.controller"
import { requireAuth } from "../middleware/auth"
import { requireRole } from "../middleware/role"

const router = express.Router()

// Only ADMIN can assign roles
router.post(
  "/set",
  requireAuth,
  requireRole("ADMIN"),
  setRole
)

router.get("/:address", fetchRole)

export default router