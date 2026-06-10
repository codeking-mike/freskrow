/*import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'FresCrow',
  projectId: '6d767ec18b127a615b3c4e85397e823e',

  chains: [sepolia],

  ssr: false,
}); */

import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';
import { http } from 'viem';


export const config = getDefaultConfig({
  appName: 'FresCrow Platforms',
  // Look for the Vercel environment variable first, fall back to your ID locally if needed
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || '6d767ec18b127a615b3c4e85397e823e', 
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(),
  },
  ssr: true,
});