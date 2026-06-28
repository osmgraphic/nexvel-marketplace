import { useState } from "react";
import { connectWallet } from "../services/wallet";
import { useEffect } from "react";

function WalletButton() {
  const [account, setAccount] = useState(null);

  useEffect(() => {
  const checkConnection = async () => {
    if (window.ethereum) {
      const accounts = await window.ethereum.request({
        method: "eth_accounts",
      });

      if (accounts.length > 0) {
        setAccount(accounts[0]);
      }
    }
  };

  checkConnection();
}, []);

useEffect(() => {
  if (window.ethereum) {
    window.ethereum.on("accountsChanged", (accounts) => {
      setAccount(accounts[0] || null);
    });
  }
}, []);

  const handleConnect = async () => {
    const wallet = await connectWallet();
    if (wallet) {
      setAccount(wallet.address);
    }
  };

  return (
    <div>
      {account ? (
        <p>Connected: {account.slice(0, 6)}...{account.slice(-4)}</p>
      ) : (
        <button onClick={handleConnect}>
          Connect Wallet
        </button>
      )}
    </div>
  );
}

export default WalletButton;