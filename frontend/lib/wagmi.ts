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
  projectId: '6d767ec18b127a615b3c4e85397e823e', 
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(),
  },
  ssr: true,
});