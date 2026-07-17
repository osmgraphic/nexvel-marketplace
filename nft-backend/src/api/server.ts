import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import nftRoutes from "./routes/nft.routes";
import listingRoutes from "./routes/listing.routes";
import activityRoutes from "./routes/activity.routes";
import userRoutes from "./routes/user.routes";
import collectionRoutes from "./routes/collection.routes";
import authRoutes from "./auth/auth.routes";
import roleRoutes from "./roles/roles.routes";
import saleRoutes from "./routes/sale.routes";
import searchRoutes from "./search/search.routes";

import { limiter } from "../middlewares/rateLimit";
import { errorHandler } from "../middlewares/error";

dotenv.config();

const app = express();

// ===============================
// 🔒 MIDDLEWARE
// ===============================
app.use(cors());
app.use(express.json());
app.use(limiter);

// ===============================
// ❤️ HEALTH
// ===============================
app.get("/", (req, res) => {
  res.send("🚀 Nexvel API Running");
});

// ===============================
// 🔥 ROUTES
// ===============================
app.use("/api/collections", collectionRoutes);
app.use("/api/listings", listingRoutes);
app.use("/api/nfts", nftRoutes);
app.use("/api/sales", saleRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/roles", roleRoutes);
app.use("/api/activity", activityRoutes);
app.use("/api/users", userRoutes);
app.use("/api/search", searchRoutes);

// ===============================
// ❌ ERROR HANDLER
// ===============================
app.use(errorHandler);

export default app;