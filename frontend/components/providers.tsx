'use client';

import { useMemo } from 'react';
import {
  QueryClient,
  QueryClientProvider,
} from '@tanstack/react-query';

import {
  WagmiProvider,
} from 'wagmi';

import {
  RainbowKitProvider,
} from '@rainbow-me/rainbowkit';

import { config } from '@/lib/wagmi';

// Create QueryClient once and reuse it
let queryClientInstance: QueryClient | null = null;

function getQueryClient() {
  if (typeof window === 'undefined') {
    return new QueryClient();
  }
  if (!queryClientInstance) {
    queryClientInstance = new QueryClient({
      defaultOptions: {
        queries: {
          staleTime: 60000,
          gcTime: 5 * 60 * 1000,
        },
      },
    });
  }
  return queryClientInstance;
}

export function Providers({
  children,
}: {
  children: React.ReactNode;
}) {
  const queryClient = useMemo(() => getQueryClient(), []);

  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}