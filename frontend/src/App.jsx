import { ConnectButton } from "@rainbow-me/rainbowkit";
import MyStakes from "./components/MyStakes";

export default function App() {
  return (
    <div className="min-h-screen p-6">
      {/* Header */}
      <header className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold text-gray-800">
          NXV Staking Dashboard
        </h1>
        <ConnectButton />
      </header>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <MyStakes />
      </div>
    </div>
  );
}
