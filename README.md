# FresCrow

FresCrow is a decentralized escrow dapp for freelance work. Clients can create escrows, fund them, and release funds once work is complete. Freelancers can accept jobs, mark delivery, and raise disputes when needed. The app is built with a Next.js frontend and a Solidity smart contract backend.

## Features

- Create an escrow for a freelancer
- Fund the escrow with ETH
- Accept the job and track progress
- Mark work as delivered and release funds
- Refund or dispute escrows when necessary
- View escrows from both the client and freelancer sides

## Tech Stack

- Frontend: Next.js, React, TypeScript, Tailwind CSS
- Web3: RainbowKit, wagmi, viem
- Smart contracts: Solidity, Foundry, OpenZeppelin
- Network: Sepolia testnet by default

## Project Structure

- frontend/: Next.js application and UI
- smart-contracts/: Foundry project containing the FresCrow Solidity contract
- frontend/abi/frescrow.ts: ABI and deployed contract address used by the frontend

## Prerequisites

Before you begin, install:

- Node.js 20+ and npm
- Foundry
- MetaMask or another wallet that supports Sepolia
- Sepolia ETH from a faucet

## 1. Clone the Repository

```bash
git clone <your-repo-url>
cd frescrow
```

## 2. Install Frontend Dependencies

```bash
cd frontend
npm install
```

## 3. Build and Test the Smart Contracts

```bash
cd ../smart-contracts
forge install
forge build
forge test
```

## 4. Deploy the Smart Contract

The deployment script expects a private key in the environment and a RPC URL for Sepolia.

```bash
cd smart-contracts
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY
forge script script/Deploy.s.sol:DeployFresCrow --rpc-url https://sepolia.infura.io/v3/YOUR_PROJECT_ID --broadcast
```

If the deployment succeeds, copy the new contract address and update it in:

- frontend/abi/frescrow.ts

> The frontend currently points to the deployed Sepolia address in the ABI file. If you deploy a new contract, update that address before running the app.

## 5. Run the Frontend

From the repository root:

```bash
cd frontend
npm run dev
```

Open http://localhost:3000 in your browser.

## 6. Connect and Use the Dapp

1. Open the app in your browser.
2. Connect your wallet.
3. Switch your wallet to the Sepolia network.
4. Make sure you have Sepolia ETH available.
5. Create or interact with an escrow from the dashboard.

## Notes

- The app is configured for Sepolia by default.
- If you want to use a different network or RPC endpoint, update the Wagmi configuration in frontend/lib/wagmi.ts.
- For local contract development, you can also use Foundry Anvil and point the frontend to that local deployment.

## Useful Foundry Commands

```bash
forge build
forge test
forge fmt
forge script script/Deploy.s.sol:DeployFresCrow --rpc-url <RPC_URL> --broadcast
```
