import dotenv from "dotenv";

dotenv.config();

export const env = {
  DB: process.env.DATABASE_URL!,
  REDIS: process.env.REDIS_URL!,
  JWT_SECRET: process.env.JWT_SECRET!,
  PORT: process.env.PORT || "4000",
  NODE_ENV: process.env.NODE_ENV || "development",
};