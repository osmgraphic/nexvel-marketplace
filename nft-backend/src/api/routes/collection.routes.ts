import { Router } from "express";

import {
  fetchCollectionFull,
  fetchCollectionFloor,
  fetchCollectionStats,
} from "../controllers/collection.controller";

const router = Router();

router.get("/:contract/full", fetchCollectionFull);

router.get("/:contract/floor", fetchCollectionFloor);

router.get("/:contract/stats", fetchCollectionStats);

export default router;