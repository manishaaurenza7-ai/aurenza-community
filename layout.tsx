import type { Metadata } from 'next';
import './globals.css';
export const metadata: Metadata = {
  title: 'Aurenza Academy | Professional Community',
  description: 'A private professional community to learn, connect and grow.'
};
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return <html lang="en"><body>{children}</body></html>;
}
