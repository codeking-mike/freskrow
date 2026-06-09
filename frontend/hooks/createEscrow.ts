'use client';

import { useWriteContract } from 'wagmi';

export function useCreateEscrow() {
  const { writeContractAsync } =
    useWriteContract();

  const createEscrow = async (
    freelancer: string,
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