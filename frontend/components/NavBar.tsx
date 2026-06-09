'use client';

import { ConnectButton } from '@rainbow-me/rainbowkit';

export default function Navbar() {

  return (
    <nav className="flex items-center justify-between p-6 border-b">

      <h1 className="text-2xl font-bold">
        FresCrow
      </h1>

      <ConnectButton />
    </nav>
  );
}