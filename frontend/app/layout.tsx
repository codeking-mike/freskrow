import { Web3Provider } from "../components/Web3Provider";
import "@/app/globals.css";

export const metadata = {
  title: 'FresCrow | Premium Web3 Freelance Escrows',
  description: 'Secure, multi-status on-chain payment protection systems.',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark bg-slate-950 text-slate-50">
      <body>
        <Web3Provider>
          {children}
        </Web3Provider>
      </body>
    </html>
  );
}