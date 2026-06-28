import { useState } from "react";
import { listNFT } from "../services/marketplace";

function ListNFT() {
  const [tokenId, setTokenId] = useState("");
  const [price, setPrice] = useState("");

  const handleList = async () => {
    await listNFT(tokenId, price);
  };

  return (
    <div>
      <h2>List NFT</h2>

      <input
        placeholder="Token ID"
        value={tokenId}
        onChange={(e) => setTokenId(e.target.value)}
      />

      <input
        placeholder="Price (ETH)"
        value={price}
        onChange={(e) => setPrice(e.target.value)}
      />

      <button onClick={handleList}>
        List NFT
      </button>
    </div>
  );
}

export default ListNFT;