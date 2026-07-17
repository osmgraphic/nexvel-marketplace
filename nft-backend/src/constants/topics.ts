import { extractTopics } from "../utils/getTopics";
import fs from "fs";
import path from "path";

const abiDir = path.join(__dirname, "../abi");

export const ALL_TOPICS: Record<string, Record<string, string>> = {};

const files = fs.readdirSync(abiDir);

for (const file of files) {
  if (file.endsWith(".ts") || file.endsWith(".json")) {
    const abiModule = require(path.join(abiDir, file));

    let abi = abiModule;

    if (abi.default) {
      abi = abi.default;
    }

    if (!Array.isArray(abi)) {
      console.warn(`⚠️ Skipping invalid ABI file: ${file}`);
      continue;
    }

    const contractName = file.replace(/\.(ts|json)/, "");

    ALL_TOPICS[contractName] = extractTopics(abi);
  }
}

// 🔥 DEBUG PRINT (IMPORTANT)
console.log("🔥 ALL_TOPICS LOADED:", JSON.stringify(ALL_TOPICS, null, 2));