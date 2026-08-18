import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // Semantic tokens — preferred for new components. Backed by CSS custom
        // properties in src/styles/tokens.css so values flip automatically with
        // the .dark class.
        bg: 'var(--color-bg)',
        surface: 'var(--color-surface)',
        'surface-elevated': 'var(--color-surface-elevated)',
        'surface-sunken': 'var(--color-surface-sunken)',
        'surface-inverse': 'var(--color-surface-inverse)',
        content: 'var(--color-text)',
        'content-muted': 'var(--color-text-muted)',
        'content-subtle': 'var(--color-text-subtle)',
        'content-inverse': 'var(--color-text-inverse)',
        outline: 'var(--color-border)',
        'outline-strong': 'var(--color-border-strong)',
        accent: 'var(--color-accent)',
        'accent-hover': 'var(--color-accent-hover)',
        'accent-soft': 'var(--color-accent-soft)',
        'accent-fg': 'var(--color-accent-fg)',
        success: 'var(--color-success)',
        warning: 'var(--color-warning)',
        danger: 'var(--color-danger)',
        info: 'var(--color-info)',
        brand: {
          50:  '#fdf2f2',
          100: '#fde8e8',
          200: '#fbd5d5',
          300: '#f8b4b4',
          400: '#f68080',
          500: '#c41230',
          600: '#a10e27',
          700: '#831122',
          800: '#6b111e',
          900: '#59121c',
        },
        gold: {
          400: '#d4a017',
          500: '#b8860b',
          600: '#9a7009',
        },
        neon: {
          cyan: '#00d9ff',
          purple: '#d946ef',
          pink: '#ec4899',
          green: '#10b981',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Playfair Display', 'Georgia', 'serif'],
      },
      borderRadius: {
        '3xl': 'var(--radius-3xl)',
      },
      boxShadow: {
        soft: 'var(--shadow-sm)',
        'soft-md': 'var(--shadow-md)',
        'soft-lg': 'var(--shadow-lg)',
        'soft-xl': 'var(--shadow-xl)',
        focus: 'var(--shadow-focus)',
      },
      backgroundImage: {
        'gradient-brand': 'linear-gradient(135deg, #c41230 0%, #6b111e 100%)',
        'gradient-neon': 'linear-gradient(135deg, #00d9ff 0%, #d946ef 100%)',
        'shimmer': 'linear-gradient(90deg, currentColor 0%, currentColor 50%, transparent 100%)',
      },
      backgroundColor: {
        'dark-primary': '#0f0f0f',
        'dark-surface': '#1a1a1a',
        'dark-border': 'rgba(255,255,255,0.1)',
      },
      textColor: {
        'dark-primary': '#f5f5f5',
        'dark-secondary': '#a0a0a0',
      },
      animation: {
        'shimmer': 'shimmer 2s infinite',
        'pulse-neon': 'pulse-neon 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'float': 'float 3s ease-in-out infinite',
        'bounce-sm': 'bounce-sm 1s ease-in-out infinite',
      },
      keyframes: {
        'pulse-neon': {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' },
        },
        'float': {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        'bounce-sm': {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-5px)' },
        },
      },
    },
  },
  plugins: [],
} satisfies Config;
