import express from "express"
import { requestMessage, verify } from "./auth.controller"

const router = express.Router()

router.post("/message", requestMessage)
router.post("/verify", verify)

export default router