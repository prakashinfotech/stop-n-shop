import React from 'react';
import { Barcode } from './Barcode';
import type { SellerLabelData } from '../../../api/sellerLabelApi';

const PAYMENT_LABEL: Record<number, string> = { 1: 'COD', 2: 'PREPAID', 3: 'PREPAID' };

interface Props { data: SellerLabelData }

/**
 * A6 (105 × 148 mm) shipping label — visually modelled on real carrier waybills
 * (Bluedart / Delhivery / Shiprocket): bold carrier brand strip, route stripe
 * (origin → destination), prominent destination pincode block, big AWB barcode,
 * scan-zone QR, payment chip, handling-icons strip, corner crop marks.
 *
 * All black-on-white so it stays crisp on thermal printers; brand accent only
 * in the top carrier strip (still legible after monochrome printing).
 */
export const ShippingSticker: React.FC<Props> = ({ data }) => {
  const paid       = data.paymentStatus === 2;
  const codAmount  = !paid && data.paymentMode === 1 ? data.totalPrice : null;
  const serviceTag = paid ? 'PRIORITY' : 'STANDARD';
  const awbNumber  = `AWB${data.orderItemId.toString().padStart(10, '0')}`;
  const routeCode  = `${(data.sellerPincode ?? '------').slice(0,3)}→${(data.buyerPincode ?? '------').slice(0,3)}`;
  const sortHub    = (data.buyerPincode ?? '').slice(0, 3);

  return (
    <article className="sticker-page bg-white text-stone-900 mx-auto relative" style={{ width: '105mm', minHeight: '148mm' }}>
      {/* Corner crop marks — visual cue for "real" labels */}
      <CornerMark className="top-0 left-0" rotate={0} />
      <CornerMark className="top-0 right-0" rotate={90} />
      <CornerMark className="bottom-0 right-0" rotate={180} />
      <CornerMark className="bottom-0 left-0" rotate={270} />

      <div className="px-2.5 py-2 space-y-1.5 text-[9pt]">

        {/* 1. Carrier brand strip — bold dark band, brand-red accent badge */}
        <div className="bg-stone-900 text-white -mx-2.5 -mt-2 px-3 py-1.5 flex items-center justify-between">
          <div className="flex items-baseline gap-2">
            <span className="font-display font-black text-[12pt] tracking-tight">
              Stop<span className="text-brand-400">'N'</span>Ship
            </span>
            <span className="text-[7pt] uppercase tracking-widest text-stone-300">Express Logistics</span>
          </div>
          <div className="text-right">
            <p className="text-[7pt] uppercase tracking-widest text-stone-400 leading-none">Service</p>
            <p className="text-[9pt] font-bold tracking-wider leading-tight">{serviceTag}</p>
          </div>
        </div>

        {/* 2. Route stripe — FROM PIN → TO PIN, monospace, prominent */}
        <div className="border-2 border-stone-900 grid grid-cols-[1fr_auto_1fr] items-center text-center font-mono">
          <div className="py-1">
            <p className="text-[6pt] uppercase tracking-widest text-stone-500 leading-none">From</p>
            <p className="text-[11pt] font-bold leading-tight">{data.sellerPincode ?? '——————'}</p>
          </div>
          <div className="px-2 text-[14pt] font-bold text-brand-500">›</div>
          <div className="py-1 bg-stone-900 text-white">
            <p className="text-[6pt] uppercase tracking-widest text-stone-300 leading-none">To</p>
            <p className="text-[11pt] font-bold leading-tight">{data.buyerPincode ?? '——————'}</p>
          </div>
        </div>

        {/* 3. Order + Payment chip */}
        <div className="flex items-start justify-between border-b border-stone-300 pb-1.5">
          <div>
            <p className="text-[6pt] uppercase tracking-widest text-stone-500 leading-none">Order #</p>
            <p className="font-mono font-bold text-[9pt] leading-tight">{data.orderNumber}</p>
            <p className="text-[7pt] text-stone-500 leading-tight">
              {new Date(data.orderDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
            </p>
          </div>
          <div className={`text-[9pt] font-bold px-2 py-1 rounded border-2 text-center leading-tight ${
            paid
              ? 'bg-emerald-50 border-emerald-700 text-emerald-800'
              : 'bg-amber-50 border-amber-700 text-amber-800'
          }`}>
            {PAYMENT_LABEL[data.paymentMode] ?? 'PAYMENT'}
            {codAmount !== null && (
              <span className="block text-[7pt] font-bold">Collect ₹{codAmount.toLocaleString('en-IN')}</span>
            )}
          </div>
        </div>

        {/* 4. AWB barcode + QR */}
        <div className="border border-stone-900 p-1.5">
          <div className="flex items-start justify-between gap-2">
            <div className="flex-1 min-w-0">
              <p className="text-[6pt] uppercase tracking-widest text-stone-500 leading-none mb-0.5">Tracking AWB</p>
              <Barcode value={data.barcodeValue} type="code128" scale={2} height={14} />
              <p className="text-[7pt] font-mono text-stone-500 mt-0.5">{awbNumber} · sort {sortHub}</p>
            </div>
            <div className="flex-shrink-0 border-l border-stone-300 pl-2">
              <p className="text-[6pt] uppercase tracking-widest text-stone-500 leading-none mb-0.5 text-center">Scan</p>
              <Barcode value={data.qrPayload} type="qrcode" scale={2} />
            </div>
          </div>
        </div>

        {/* 5. DELIVER TO panel — destination pincode huge for sorters */}
        <div className="border-2 border-stone-900">
          <p className="text-[7pt] uppercase tracking-widest bg-stone-900 text-white px-2 py-0.5 font-bold">Deliver to</p>
          <div className="p-2 text-[9pt] leading-snug">
            <p className="font-bold text-[10.5pt]">{data.buyerName ?? 'Customer'}</p>
            {data.addressLine1 && <p>{data.addressLine1}</p>}
            {data.addressLine2 && <p>{data.addressLine2}</p>}
            <p>{[data.buyerCity, data.buyerState].filter(Boolean).join(', ')}</p>
            {/* Pincode emphasized: thick border block, huge tracking */}
            <div className="mt-1 border-2 border-stone-900 bg-stone-50 px-2 py-1 inline-block">
              <p className="font-mono font-black text-[18pt] tracking-[0.15em] leading-none">{data.buyerPincode ?? '——————'}</p>
            </div>
            {data.buyerPhoneMasked && <p className="text-[8pt] text-stone-700 mt-1">Ph: <span className="font-mono">{data.buyerPhoneMasked}</span></p>}
          </div>
        </div>

        {/* 6. SHIPS FROM panel — compact */}
        <div className="border border-stone-400">
          <p className="text-[7pt] uppercase tracking-widest bg-stone-100 text-stone-700 px-2 py-0.5 font-bold">Ships from</p>
          <div className="p-1.5 text-[8pt] leading-snug text-stone-700">
            <p className="font-bold text-[9pt] text-stone-900">{data.sellerBusinessName ?? '—'}</p>
            {data.sellerAddressLine1 && <p>{data.sellerAddressLine1}</p>}
            <p>{[data.sellerCity, data.sellerState, data.sellerPincode].filter(Boolean).join(', ')}</p>
            {data.sellerSupportPhone && <p className="font-mono">Ph: {data.sellerSupportPhone}</p>}
          </div>
        </div>

        {/* 7. Item summary + dimensions */}
        <div className="border-t border-stone-300 pt-1 text-[8pt] text-stone-800">
          <div className="flex justify-between font-medium gap-2">
            <span className="truncate flex-1">{data.productName}</span>
            <span className="font-bold">× {data.quantity}</span>
          </div>
          <div className="flex justify-between mt-0.5 text-[7pt] text-stone-500">
            <span className="truncate flex-1">
              {[data.size && `Size ${data.size}`, data.color, data.variantSku].filter(Boolean).join(' · ') || '—'}
            </span>
            <span className="font-mono">
              {data.variantWeightGm != null ? `Wt ${data.variantWeightGm}g` : ''}
            </span>
          </div>
        </div>

        {/* 8. Handling icons — purely visual, signals "real" label */}
        <div className="flex items-center justify-around border border-stone-300 bg-stone-50 py-1 text-stone-700">
          <HandlingIcon label="HANDLE WITH CARE">
            <svg viewBox="0 0 24 24" className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 2L4 7v6c0 5 3.5 8.5 8 9 4.5-.5 8-4 8-9V7l-8-5z" />
            </svg>
          </HandlingIcon>
          <HandlingIcon label="THIS SIDE UP">
            <svg viewBox="0 0 24 24" className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 19V5M5 12l7-7 7 7" />
            </svg>
          </HandlingIcon>
          <HandlingIcon label="KEEP DRY">
            <svg viewBox="0 0 24 24" className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M12 2.5c-3 4.5-6 8-6 11.5a6 6 0 0012 0c0-3.5-3-7-6-11.5z" />
            </svg>
          </HandlingIcon>
          <HandlingIcon label="DO NOT BEND">
            <svg viewBox="0 0 24 24" className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="3" y="6" width="18" height="12" rx="1" />
              <path d="M3 12h18" />
            </svg>
          </HandlingIcon>
        </div>

        {/* 9. Footer micro-text */}
        <p className="text-[6.5pt] text-stone-500 text-center leading-tight pt-0.5">
          Route: <span className="font-mono font-bold text-stone-700">{routeCode}</span>
          {' · '}If undelivered, return to seller address above.
        </p>
      </div>
    </article>
  );
};

// ── Crop marks at each corner ─────────────────────────────────────────────────
const CornerMark: React.FC<{ className?: string; rotate: number }> = ({ className = '', rotate }) => (
  <svg
    aria-hidden
    viewBox="0 0 16 16"
    className={`absolute w-3 h-3 text-stone-400 ${className}`}
    style={{ transform: `rotate(${rotate}deg)` }}
  >
    <path d="M0 0 H10 M0 0 V10" stroke="currentColor" strokeWidth="1" fill="none" />
  </svg>
);

// ── Small icon + label cluster for the handling strip ────────────────────────
const HandlingIcon: React.FC<{ label: string; children: React.ReactNode }> = ({ label, children }) => (
  <div className="flex flex-col items-center gap-0.5">
    {children}
    <span className="text-[5pt] font-bold tracking-wider">{label}</span>
  </div>
);
