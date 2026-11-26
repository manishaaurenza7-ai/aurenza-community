import type { Config } from 'tailwindcss';
const config: Config = {
  content: ['./app/**/*.{js,ts,jsx,tsx}', './components/**/*.{js,ts,jsx,tsx}'],
  theme: { extend: { colors: { ink: '#101B2D', brand: '#173D67', gold: '#C7A56A' } } },
  plugins: []
};
export default config;
