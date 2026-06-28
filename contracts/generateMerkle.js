import fs from "fs";
import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";

// 1. Load airdrop.json
const airdrop = JSON.parse(fs.readFileSync("airdrop.json"));

// 2. Create leaves
const leaves = airdrop.map((item) =>
  keccak256(
    Buffer.from(
      `${item.address.toLowerCase()}${item.amount}`,
      "utf8"
    )
  )
);

// 3. Build Merkle Tree
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

// 4. Save proofs for every user
const proofs = {};

airdrop.forEach((item, index) => {
  const leaf = leaves[index];
  const proof = tree.getHexProof(leaf);

  proofs[item.address] = {
    amount: item.amount,
    proof,
  };
});

// 5. Write results
fs.writeFileSync("proofs.json", JSON.stringify(proofs, null, 2));

console.log("Merkle Root:", tree.getHexRoot());
console.log("Proofs saved to proofs.json");
