'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { parseEther, formatEther } from 'viem';
import { FRESCROW_ADDRESS, FRESCROW_ABI, STATUS_MAP } from '@/abi/frescrow';
import { Briefcase, User, ShieldAlert, Coins, ArrowRight, Loader2, ExternalLink, Clock, CheckCircle, PackageCheck, Wallet } from 'lucide-react';

export default function UpworkWeb3Marketplace() {
  const { address, isConnected } = useAccount();
  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isTxConfirming, isSuccess: isTxConfirmed } = useWaitForTransactionReceipt({ hash });

  // Navigation & Role State
  const [userRole, setUserRole] = useState<'none' | 'freelancer' | 'client'>('none');
  const [isRegistered, setIsRegistered] = useState(false);
  const [username, setUsername] = useState('');

  // Form Inputs for Client Posting
  const [targetFreelancer, setTargetFreelancer] = useState('');
  const [jobTitle, setJobTitle] = useState('');
  const [jobBudget, setJobBudget] = useState('');
  const [associatedIds, setAssociatedIds] = useState<number[]>([]);

  // --- PERSISTENCE LAYER VIA LOCALSTORAGE ---
  // Automatically check for an existing profile whenever the active wallet address changes
  useEffect(() => {
    if (isConnected && address) {
      const savedProfileRaw = localStorage.getItem(`frescrow_profile_${address.toLowerCase()}`);
      
      if (savedProfileRaw) {
        try {
          const profile = JSON.parse(savedProfileRaw);
          setUsername(profile.username);
          setUserRole(profile.userRole);
          setIsRegistered(true);
        } catch (error) {
          console.error("Error reading saved profile sequence from localStorage", error);
        }
      } else {
        // No saved profile for this specific address, reset UI state back to initialization gating
        setUserRole('none');
        setIsRegistered(false);
        setUsername('');
      }
    } else {
      // Wallet disconnected completely
      setUserRole('none');
      setIsRegistered(false);
      setUsername('');
    }
  }, [isConnected, address]);

  // Handler to commit profile metrics to localStorage safely
  const handleRegisterProfile = (e: React.FormEvent) => {
    e.preventDefault();
    if (username.trim() && userRole !== 'none' && address) {
      const profileData = {
        username: username.trim(),
        userRole: userRole
      };
      
      // Lock it down using a unique key derived from the user's active wallet address
      localStorage.setItem(`frescrow_profile_${address.toLowerCase()}`, JSON.stringify(profileData));
      setIsRegistered(true);
    }
  };

  // Handler to drop profile persistence states on manual sign-out actions
  const handleLogoutProfile = () => {
    if (address) {
      localStorage.removeItem(`frescrow_profile_${address.toLowerCase()}`);
    }
    setUserRole('none');
    setIsRegistered(false);
    setUsername('');
  };

  // --- CHAIN FEED CONTRACT DATA READERS ---
  const { data: clientIdsRaw, refetch: refetchClientJobs } = useReadContract({
    address: FRESCROW_ADDRESS,
    abi: FRESCROW_ABI,
    functionName: 'getClientEscrows',
    args: [address as `0x${string}`],
    query: { enabled: isConnected && userRole === 'client' && !!address }
  });

  const { data: freelancerIdsRaw, refetch: refetchFreelancerJobs } = useReadContract({
    address: FRESCROW_ADDRESS,
    abi: FRESCROW_ABI,
    functionName: 'getFreelancerEscrows',
    args: [address as `0x${string}`],
    query: { enabled: isConnected && userRole === 'freelancer' && !!address }
  });

  useEffect(() => {
    if (userRole === 'client' && clientIdsRaw) {
      setAssociatedIds([...(clientIdsRaw as bigint[])].map(id => Number(id)).reverse());
    } else if (userRole === 'freelancer' && freelancerIdsRaw) {
      setAssociatedIds([...(freelancerIdsRaw as bigint[])].map(id => Number(id)).reverse());
    } else {
      setAssociatedIds([]);
    }
  }, [clientIdsRaw, freelancerIdsRaw, userRole]);

  const refreshMarketplaceFeed = () => {
    if (userRole === 'client') refetchClientJobs();
    if (userRole === 'freelancer') refetchFreelancerJobs();
  };

  useEffect(() => {
    if (isTxConfirmed) refreshMarketplaceFeed();
  }, [isTxConfirmed]);

  const handlePostJobAndFund = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!targetFreelancer || !jobTitle) return;
    writeContract({
      address: FRESCROW_ADDRESS,
      abi: FRESCROW_ABI,
      functionName: 'createEscrow',
      args: [targetFreelancer as `0x${string}`, jobTitle],
    });
  };

  // --- RENDER ROUTINES ---

  if (!isConnected) {
    return (
      <div className="min-h-screen bg-slate-950 text-slate-50 flex flex-col justify-center items-center p-6 bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-indigo-950/40 via-slate-950 to-slate-950">
        <div className="text-center max-w-xl space-y-6">
          <div className="inline-flex items-center gap-2 px-3 py-1 bg-indigo-950/60 border border-indigo-800 rounded-full text-indigo-400 text-xs font-semibold">
            ✦ Decentralized Freelance Economy
          </div>
          <h1 className="text-5xl font-black tracking-tight leading-none bg-gradient-to-r from-slate-100 via-indigo-200 to-cyan-400 bg-clip-text text-transparent sm:text-6xl">
            Secure Trustless Smart Escrows
          </h1>
          <p className="text-slate-400 text-lg">
            Welcome to FresCrow, the premium P2P Web3 Escrow framework that connects elite freelancers and global clients to make and accept payments using automated immutable contract infrastructure.
          </p>
          <p className="text-slate-200 text-lg">Receive and Accept Payments from clients worldwide</p>
          <div className="flex justify-center pt-4">
            <ConnectButton label="Connect Web3 Wallet to Enter" />
          </div>
        </div>
      </div>
    );
  }

  if (userRole === 'none') {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col justify-center items-center p-6">
        <div className="max-w-3xl w-full text-center space-y-8">
          <h2 className="text-3xl font-extrabold text-slate-100">Welcome to Frescrow. Choose your path:</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <button 
              onClick={() => setUserRole('freelancer')}
              className="group bg-slate-900/40 border border-slate-800/80 p-8 rounded-2xl text-left hover:border-indigo-500 hover:bg-slate-900/80 transition-all shadow-xl space-y-4"
            >
              <div className="w-12 h-12 rounded-xl bg-indigo-950 border border-indigo-800 flex items-center justify-center text-indigo-400 group-hover:bg-indigo-600 group-hover:text-white transition-colors">
                <Briefcase size={24} />
              </div>
              <h3 className="text-xl font-bold text-slate-200 group-hover:text-indigo-400 transition-colors">I am a Freelancer</h3>
              <p className="text-slate-400 text-sm leading-relaxed">
                Accept payments from clients securely, manage job delivery lifecycles, and claim securely held multi-milestone escrow deposits.
              </p>
              <div className="text-indigo-400 flex items-center gap-1 text-xs font-bold uppercase tracking-wider pt-2">
                Enter Dashboard <ArrowRight size={14} className="group-hover:translate-x-1 transition-transform" />
              </div>
            </button>

            <button 
              onClick={() => setUserRole('client')}
              className="group bg-slate-900/40 border border-slate-800/80 p-8 rounded-2xl text-left hover:border-cyan-500 hover:bg-slate-900/80 transition-all shadow-xl space-y-4"
            >
              <div className="w-12 h-12 rounded-xl bg-cyan-950 border border-cyan-800 flex items-center justify-center text-cyan-400 group-hover:bg-cyan-600 group-hover:text-white transition-colors">
                <User size={24} />
              </div>
              <h3 className="text-xl font-bold text-slate-200 group-hover:text-cyan-400 transition-colors">I am a Client</h3>
              <p className="text-slate-400 text-sm leading-relaxed">
                Create payment contracts, safe-lock project fees inside an escrow runtime container, and retain granular release-of-funds privileges.
              </p>
              <div className="text-cyan-400 flex items-center gap-1 text-xs font-bold uppercase tracking-wider pt-2">
                Enter Dashboard <ArrowRight size={14} className="group-hover:translate-x-1 transition-transform" />
              </div>
            </button>
          </div>
        </div>
      </div>
    );
  }

  if (!isRegistered) {
    return (
      <div className="min-h-screen bg-slate-950 flex flex-col justify-center items-center p-6">
        {/* CHANGED TO: handleRegisterProfile */}
        <form onSubmit={handleRegisterProfile} className="max-w-md w-full bg-slate-900/60 border border-slate-800 rounded-2xl p-8 space-y-6 shadow-xl">
          <div className="space-y-2 text-center">
            <h2 className="text-2xl font-bold tracking-tight">Create Workspace Profile</h2>
            <p className="text-slate-400 text-sm">Initialize your identity profile as a <span className="text-indigo-400 font-bold capitalize">{userRole}</span>.</p>
          </div>
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Full Professional Name / Alias</label>
            <input 
              type="text" 
              required
              placeholder="e.g., Alice Dev" 
              className="w-full bg-slate-950 border border-slate-800 rounded-xl p-3 text-sm text-slate-100 focus:outline-none focus:border-indigo-500"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
            />
          </div>
          <button type="submit" className="w-full bg-indigo-600 hover:bg-indigo-500 text-sm font-semibold py-3 rounded-xl transition-colors">
            Finalize Profile Setup
          </button>
        </form>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-50">
      
      {/* Header Bar */}
      <nav className="bg-slate-900/40 border-b border-slate-900 px-6 py-4 sticky top-0 backdrop-blur-md z-50">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row justify-between items-center gap-4">
          <div className="flex items-center gap-3">
            <span className="text-2xl font-black bg-gradient-to-r from-indigo-400 to-cyan-400 bg-clip-text text-transparent">FresCrow Hub</span>
            <span className="px-2.5 py-0.5 rounded text-[11px] font-bold tracking-wider uppercase bg-slate-800 text-slate-300 border border-slate-700">
              {userRole} Dashboard
            </span>
          </div>
          <div className="flex items-center gap-4">
            <div className="text-right hidden md:block">
              <p className="text-sm font-bold text-slate-200">{username}</p>
              <p className="text-xs font-mono text-slate-500 truncate max-w-[150px]">{address}</p>
            </div>
            <ConnectButton showBalance={false} />
            {/* CHANGED TO: handleLogoutProfile */}
            <button 
              onClick={handleLogoutProfile} 
              className="text-xs text-rose-400 hover:text-rose-300 underline font-medium"
            >
              Log out
            </button>
          </div>
        </div>
      </nav>

      {/* Main Grid Workspace */}
      <div className="max-w-7xl mx-auto p-6 grid grid-cols-1 lg:grid-cols-3 gap-8">
        
        {/* LEFT COLUMN PANEL: FORM INTERACTION */}
        <div className="space-y-6 lg:col-span-1">
          {userRole === 'client' ? (
            <div className="bg-slate-900/60 border border-slate-800 p-6 rounded-2xl shadow-lg space-y-4 sticky top-24">
              <div className="flex items-center gap-2 border-b border-slate-800 pb-3 text-cyan-400">
                <Coins size={20} />
                <h3 className="font-bold text-slate-100">Initialize Escrow Job</h3>
              </div>
              <form onSubmit={handlePostJobAndFund} className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">Contractor Freelancer Address</label>
                  <input 
                    type="text" 
                    placeholder="0x..." 
                    required
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2.5 text-xs font-mono text-slate-100 focus:outline-none focus:border-cyan-500"
                    value={targetFreelancer}
                    onChange={(e) => setTargetFreelancer(e.target.value)}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">Project Specification / Title</label>
                  <input 
                    type="text" 
                    placeholder="e.g., Next.js Frontend Implementation" 
                    required
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2.5 text-xs text-slate-100 focus:outline-none focus:border-cyan-500"
                    value={jobTitle}
                    onChange={(e) => setJobTitle(e.target.value)}
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">Contract Budget (ETH)</label>
                  <input 
                    type="number" 
                    step="0.0001" 
                    placeholder="0.1" 
                    required
                    className="w-full bg-slate-950 border border-slate-800 rounded-xl p-2.5 text-xs font-mono text-slate-100 focus:outline-none focus:border-cyan-500"
                    value={jobBudget}
                    onChange={(e) => setJobBudget(e.target.value)}
                  />
                </div>
                <button 
                  type="submit" 
                  disabled={isPending}
                  className="w-full bg-cyan-600 hover:bg-cyan-500 disabled:bg-slate-800 disabled:text-slate-500 py-2.5 rounded-xl font-semibold text-sm text-slate-950 transition-colors flex items-center justify-center gap-2"
                >
                  {isPending && <Loader2 className="animate-spin" size={16} />}
                  Create Escrow Layout
                </button>
              </form>
            </div>
          ) : (
            <div className="bg-slate-900/40 border border-slate-800/80 p-6 rounded-2xl text-slate-300 space-y-4 sticky top-24">
              <h3 className="font-bold text-lg text-slate-100">Freelancer Terminal</h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                Your assigned contracts are listed dynamically. As your clients instantiate smart escrow protocols referencing your public key, jobs will display here in real-time.
              </p>
              <button 
                onClick={refreshMarketplaceFeed}
                className="w-full bg-slate-800 hover:bg-slate-700 border border-slate-700 p-2 text-xs rounded-xl font-semibold transition-colors"
              >
                Sync Feed Arrays
              </button>
            </div>
          )}

          {/* Transaction Receipt Status Log */}
          {(isPending || hash) && (
            <div className="bg-slate-900 border border-slate-800 p-4 rounded-xl space-y-2 shadow-inner">
              <h4 className="text-xs font-bold text-slate-400 uppercase tracking-widest">Network Node Transceiver</h4>
              {isPending && (
                <div className="flex items-center gap-2 text-xs text-amber-400">
                  <Loader2 className="animate-spin" size={14} />
                  <span>Awaiting Cryptographic Wallet Authorization...</span>
                </div>
              )}
              {hash && (
                <div className="text-xs space-y-1.5 font-mono">
                  <div className="flex justify-between text-slate-500">
                    <span>TX HASH:</span>
                    <a href={`https://sepolia.etherscan.io/tx/${hash}`} target="_blank" rel="noreferrer" className="text-indigo-400 hover:underline inline-flex items-center gap-0.5">
                      Etherscan <ExternalLink size={10} />
                    </a>
                  </div>
                  <p className="text-slate-300 truncate">{hash}</p>
                  {isTxConfirming && <p className="text-cyan-400 animate-pulse font-sans">Syncing block inclusion data...</p>}
                  {isTxConfirmed && <p className="text-emerald-400 font-bold font-sans">✓ Blockchain Settlement Complete!</p>}
                </div>
              )}
            </div>
          )}
        </div>

        {/* RIGHT COLUMN AREA: JOBS FEED LIST */}
        <div className="lg:col-span-2 space-y-4">
          <div className="flex justify-between items-center pb-2">
            <h3 className="text-xl font-bold text-slate-200">
              {userRole === 'client' ? 'Contracts You Instantiated' : 'Your Assigned Contracts'}
            </h3>
            <span className="text-xs bg-slate-900 border border-slate-800 px-2.5 py-1 rounded-lg text-slate-400 font-mono">
              Count: {associatedIds.length}
            </span>
          </div>

          {associatedIds.length > 0 ? (
            <div className="space-y-4">
              {associatedIds.map((id) => (
                <JobCard 
                  key={id} 
                  escrowId={id} 
                  userRole={userRole} 
                  userAddress={address!} 
                  writeContract={writeContract} 
                  isPending={isPending}
                  presetBudget={jobBudget}
                />
              ))}
            </div>
          ) : (
            <div className="bg-slate-900/20 border-2 border-dashed border-slate-800 rounded-2xl p-16 text-center text-slate-500 space-y-2">
              <Wallet size={32} className="mx-auto text-slate-700" />
              <p>No contractual smart escrow instances identified matching your active wallet parameters.</p>
            </div>
          )}
        </div>

      </div>
    </div>
  );
}

// --- KEEP YOUR SAME JOBCARD INFRASTRUCTURE EXACTLY AS DEFINED PREVIOUSLY BELOW ---
interface JobCardProps {
  escrowId: number;
  userRole: 'client' | 'freelancer';
  userAddress: string;
  writeContract: any;
  isPending: boolean;
  presetBudget: string;
}

function JobCard({ escrowId, userRole, userAddress, writeContract, isPending, presetBudget }: JobCardProps) {
  const [fundingValue, setFundingValue] = useState(presetBudget || '0.01');

  const { data: escrow } = useReadContract({
    address: FRESCROW_ADDRESS,
    abi: FRESCROW_ABI,
    functionName: 'getEscrow',
    args: [BigInt(escrowId)],
  });

  if (!escrow) {
    return (
      <div className="bg-slate-900/40 border border-slate-800/60 p-6 rounded-xl animate-pulse h-32 flex items-center justify-center">
        <Loader2 className="animate-spin text-slate-700" size={20} />
      </div>
    );
  }

  const [clientAddr, freelancerAddr, amountRaw, releasedRaw, statusInt, titleStr] = escrow as [string, string, bigint, bigint, number, string];

  const handleAction = (functionName: string, options?: { value?: bigint }) => {
    writeContract({
      address: FRESCROW_ADDRESS,
      abi: FRESCROW_ABI,
      functionName,
      args: [BigInt(escrowId)],
      value: options?.value,
    });
  };

  return (
    <div className="bg-slate-900/50 border border-slate-800/80 rounded-xl overflow-hidden hover:border-slate-700 transition-colors shadow-md">
      <div className="p-5 border-b border-slate-800/60 bg-slate-900/20 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] font-mono font-bold px-2 py-0.5 bg-slate-950 text-slate-400 border border-slate-800 rounded">
              INDEX ID #{escrowId}
            </span>
            <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
              statusInt === 1 ? 'bg-amber-950 text-amber-400 border border-amber-900' :
              statusInt === 2 ? 'bg-indigo-950 text-indigo-400 border border-indigo-900' :
              statusInt === 3 || statusInt === 4 ? 'bg-purple-950 text-purple-400 border border-purple-900' :
              statusInt === 7 ? 'bg-emerald-950 text-emerald-400 border border-emerald-900' :
              'bg-slate-950 text-slate-400 border border-slate-800'
            }`}>
              {STATUS_MAP[statusInt] || 'Created'}
            </span>
          </div>
          <h4 className="text-lg font-bold text-slate-100 mt-2">{titleStr || "Unspecified Assignment Contract"}</h4>
        </div>
        <div className="text-right bg-slate-950/80 p-2 rounded-xl border border-slate-900 min-w-[120px]">
          <span className="text-[10px] text-slate-500 block uppercase font-bold tracking-wider">Locked Vault</span>
          <span className="text-lg font-black font-mono text-emerald-400">{formatEther(amountRaw)} ETH</span>
        </div>
      </div>
      <div className="p-5 grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
        <div className="space-y-1.5">
          <p className="text-slate-500 font-medium">Client Signee:</p>
          <p className="font-mono bg-slate-950 p-1.5 border border-slate-900 rounded-lg text-slate-300 truncate select-all">
            {clientAddr}
          </p>
        </div>
        <div className="space-y-1.5">
          <p className="text-slate-500 font-medium">Assigned Freelancer:</p>
          <p className="font-mono bg-slate-950 p-1.5 border border-slate-900 rounded-lg text-slate-300 truncate select-all">
            {freelancerAddr}
          </p>
        </div>
      </div>
      <div className="p-5 bg-slate-950/40 border-t border-slate-800/40 flex flex-wrap items-center justify-between gap-4">
        <div className="text-[11px] text-slate-500 flex items-center gap-1">
          <Clock size={12} /> Last synced directly from contract mapping data stack.
        </div>
        <div className="flex items-center gap-2">
          {statusInt === 0 && userRole === 'client' && userAddress.toLowerCase() === clientAddr.toLowerCase() && (
            <div className="flex items-center gap-2">
              <input 
                type="number" 
                step="0.001"
                className="bg-slate-950 border border-slate-800 rounded-lg p-1.5 text-xs font-mono w-20 focus:outline-none"
                value={fundingValue}
                onChange={(e) => setFundingValue(e.target.value)}
              />
              <button 
                disabled={isPending}
                onClick={() => handleAction('fundEscrow', { value: parseEther(fundingValue) })}
                className="bg-emerald-600 hover:bg-emerald-500 text-slate-950 text-xs font-bold px-3 py-1.5 rounded-lg transition-colors"
              >
                Deposit & Fund Job
              </button>
            </div>
          )}
          {statusInt === 1 && userRole === 'freelancer' && userAddress.toLowerCase() === freelancerAddr.toLowerCase() && (
            <button 
              disabled={isPending}
              onClick={() => handleAction('acceptJob')}
              className="bg-indigo-600 hover:bg-indigo-500 text-xs font-bold px-4 py-2 rounded-lg text-white transition-colors flex items-center gap-1"
            >
              <CheckCircle size={14} /> Accept Contract
            </button>
          )}
          {statusInt === 2 && userRole === 'freelancer' && userAddress.toLowerCase() === freelancerAddr.toLowerCase() && (
            <button 
              disabled={isPending}
              onClick={() => handleAction('markDelivered')}
              className="bg-amber-600 hover:bg-amber-500 text-xs font-bold px-4 py-2 rounded-lg text-white transition-colors flex items-center gap-1"
            >
              <PackageCheck size={14} /> Mark Job Delivered
            </button>
          )}
          {statusInt === 3 && userRole === 'freelancer' && userAddress.toLowerCase() === freelancerAddr.toLowerCase() && (
            <button 
              disabled={isPending}
              onClick={() => handleAction('markCompleted')}
              className="bg-purple-600 hover:bg-purple-500 text-xs font-bold px-4 py-2 rounded-lg text-white transition-colors"
            >
              Complete Lifecycle Pipeline
            </button>
          )}
          {statusInt === 4 && userRole === 'client' && userAddress.toLowerCase() === clientAddr.toLowerCase() && (
            <button 
              disabled={isPending}
              onClick={() => handleAction('releaseFunds')}
              className="bg-emerald-600 hover:bg-emerald-500 text-slate-950 text-xs font-bold px-4 py-2 rounded-lg transition-colors"
            >
              Approve Output & Pay Freelancer
            </button>
          )}
        </div>
      </div>
    </div>
  );
}