import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';
import { DEFAULT_PRODUCT_IMAGE } from './constants/productImage';

// Global fallback for any <img> whose src 404s — swap to default placeholder once.
window.addEventListener(
  'error',
  (e) => {
    const t = e.target as HTMLImageElement | null;
    if (t && t.tagName === 'IMG' && !t.dataset.fallbackApplied) {
      t.dataset.fallbackApplied = '1';
      t.src = DEFAULT_PRODUCT_IMAGE;
    }
  },
  true,
);

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
