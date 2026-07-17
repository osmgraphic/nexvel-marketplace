import { Router } from "express"
import {
  searchAll,
  searchNFTController,
  searchCollectionController,
  searchListingController
} from "./search.controller"

const router = Router()

router.get("/", searchAll)
router.get("/nfts", searchNFTController)
router.get("/collections", searchCollectionController)
router.get("/listings", searchListingController)

export default router