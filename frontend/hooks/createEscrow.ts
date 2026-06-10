'use client';

import { useWriteContract } from 'wagmi';

import {
  FRESCROW_ABI,
  FRESCROW_ADDRESS,
} from '@/abi/frescrow';

export function useCreateEscrow() {
  const { writeContractAsync } =
    useWriteContract();

  const createEscrow = async (
    freelancer: `0x${string}`,
    title: string
  ) => {
    return writeContractAsync({
      address: FRESCROW_ADDRESS,
      abi: FRESCROW_ABI,
      functionName: 'createEscrow',
      args: [freelancer, title],
    });
  };

  return { createEscrow };
}