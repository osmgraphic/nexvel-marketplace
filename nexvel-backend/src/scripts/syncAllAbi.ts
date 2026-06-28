import fs from "fs";
import path from "path";

// 📍 Contracts out directory
const CONTRACTS_OUT = path.resolve(
  __dirname,
  "../../../contracts/out"
);

const DEST_DIR = path.resolve(
  __dirname,
  "../abi"
);

// Ensure abi folder exists
if (!fs.existsSync(DEST_DIR)) {
  fs.mkdirSync(DEST_DIR, { recursive: true });
}

// Loop through all contract folders
const folders = fs.readdirSync(CONTRACTS_OUT);

for (const folder of folders) {
  const folderPath = path.join(CONTRACTS_OUT, folder);

  if (!fs.statSync(folderPath).isDirectory()) continue;

  // Extract contract name (remove .sol)
  const contractName = folder.replace(".sol", "");

  const jsonPath = path.join(folderPath, `${contractName}.json`);

  if (!fs.existsSync(jsonPath)) continue;

  const file = JSON.parse(fs.readFileSync(jsonPath, "utf-8"));

  const destPath = path.join(DEST_DIR, `${contractName}.ts`);

  fs.writeFileSync(
    destPath,
    `export default ${JSON.stringify(file.abi, null, 2)};\n`
  );

  console.log(`✅ Synced: ${contractName}`);
}

console.log("🚀 All ABIs synced successfully!");