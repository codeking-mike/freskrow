import {
  useReadContract,
  useWriteContract,
} from 'wagmi';

import {
  FRESCROW_ABI,
  FRESCROW_ADDRESS,
} from '@/abi/frescrow';

export function useCreateEscrow() {

  return useWriteContract();
}