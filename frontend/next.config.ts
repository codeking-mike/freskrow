import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Experimental features for faster builds and optimized imports
  experimental: {
    optimizePackageImports: [
      '@rainbow-me/rainbowkit',
      'wagmi',
      'viem',
    ],
  },
};

export default nextConfig;
