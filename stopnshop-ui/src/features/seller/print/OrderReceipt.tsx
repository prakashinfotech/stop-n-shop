import React from 'react';
import type { SellerLabelData } from '../../../api/sellerLabelApi';

const PAYMENT_LABEL: Record<number, string> = { 1: 'Cash on Delivery', 2: 'Online (Prepaid)', 3: 'Wallet' };

interface Props { data: SellerLabelData }

/**
 * A4 tax-invoice / fulfilment slip — modelled on real Indian GST invoices.
 *
 * Visual structure:
 *   1. Brand-red header band with logo + "TAX INVOICE" badge + invoice meta
 *   2. Seller block + GSTIN / PAN strip
 *   3. Split BILL TO + SHIP TO panels
 *   4. Line items table with HSN/SAC column
 *   5. GST breakdown — CGST + SGST when intrastate, IGST when interstate
 *   6. Amount-in-words line
 *   7. Authorised signatory + Terms & Conditions footer
 *
 * GST split heuristic: intrastate (CGST+SGST) when buyerState matches sellerState
 * (case-insensitive), interstate (IGST) otherwise. Default HSN = 6109 (T-shirts /
 * apparel) since the data shape doesn't carry per-line HSN yet.
 */
export const OrderReceipt: React.FC<Props> = ({ data }) => {
  const itemSubtotal = data.unitPrice * data.quantity;
  const tax          = data.taxAmount;
  const grand        = data.totalPrice;

  // GST split — intrastate vs interstate
  const intrastate = !!(data.buyerState && data.sellerState
                        && data.buyerState.trim().toLowerCase() === data.sellerState.trim().toLowerCase());
  const cgst = intrastate ? tax / 2 : 0;
  const sgst = intrastate ? tax / 2 : 0;
  const igst = intrastate ? 0 : tax;

  // Invoice metadata — derive a numeric invoice number from the order item id.
  const invoiceNumber = `INV-${data.orderItemId.toString().padStart(8, '0')}`;
  const hsnDefault    = '6109';   // GST HSN for T-shirts / apparel; placeholder when not in data

  return (
    <article className="receipt-page bg-white text-stone-900 mx-auto" style={{ width: '210mm', minHeight: '297mm' }}>
      <div className="text-[10pt] leading-snug">

        {/* 1. BRAND HEADER BAND ─────────────────────────────────────────────── */}
        <header className="bg-gradient-to-r from-brand-700 via-brand-500 to-brand-600 text-white px-10 py-6 flex items-center justify-between">
          <div className="flex items-center gap-4">
            {data.sellerLogoUrl ? (
              <img
                src={data.sellerLogoUrl}
                alt={data.sellerBusinessName ?? 'Seller'}
                className="h-12 w-12 rounded bg-white p-1 object-contain"
              />
            ) : (
              <div className="h-12 w-12 rounded bg-white/95 flex items-center justify-center font-display font-black text-[18pt] text-brand-600">
                S
              </div>
            )}
            <div>
              <p className="font-display text-[20pt] font-bold leading-tight">StopNShop</p>
              <p className="text-[9pt] text-white/80 leading-tight">Fashion marketplace</p>
            </div>
          </div>
          <div className="text-right">
            <span className="inline-block bg-white/95 text-brand-700 font-bold text-[10pt] tracking-widest px-3 py-1 rounded uppercase">
              Tax Invoice
            </span>
            <p className="text-[8pt] uppercase tracking-widest text-white/80 mt-2">Original for Recipient</p>
          </div>
        </header>

        {/* 2. INVOICE META + SELLER STRIP ───────────────────────────────────── */}
        <section className="px-10 pt-6 pb-4 grid grid-cols-[1.4fr_1fr] gap-8 border-b-2 border-stone-200">
          {/* Seller */}
          <div>
            <p className="text-[8pt] uppercase tracking-widest text-stone-500 mb-1">Sold by</p>
            <p className="font-bold text-[12pt] text-stone-900">{data.sellerBusinessName ?? 'Seller'}</p>
            {data.sellerAddressLine1 && <p className="text-stone-700">{data.sellerAddressLine1}</p>}
            {data.sellerAddressLine2 && <p className="text-stone-700">{data.sellerAddressLine2}</p>}
            <p className="text-stone-700">
              {[data.sellerCity, data.sellerState, data.sellerPincode].filter(Boolean).join(', ')}
            </p>
            <div className="mt-2 text-[9pt] text-stone-600 space-y-0.5">
              {data.sellerSupportEmail && <p>{data.sellerSupportEmail}</p>}
              {data.sellerSupportPhone && <p>{data.sellerSupportPhone}</p>}
            </div>
            {data.sellerGstNumber && (
              <div className="mt-3 inline-flex flex-col bg-stone-50 border border-stone-200 rounded px-3 py-1.5 text-[9pt]">
                <span className="text-stone-500 text-[7pt] uppercase tracking-widest">GSTIN</span>
                <span className="font-mono font-bold text-stone-900">{data.sellerGstNumber}</span>
              </div>
            )}
          </div>

          {/* Invoice meta block */}
          <div className="text-[9pt]">
            <MetaRow label="Invoice #"     value={invoiceNumber} mono />
            <MetaRow label="Order #"       value={data.orderNumber} mono />
            <MetaRow
              label="Invoice date"
              value={new Date(data.orderDate).toLocaleDateString('en-IN',
                { day: '2-digit', month: 'short', year: 'numeric' })}
            />
            <MetaRow label="Place of supply" value={data.buyerState ?? '—'} />
            <MetaRow label="Reverse charge" value="No" />
            <div className="mt-3 border-t border-stone-200 pt-2">
              <MetaRow
                label="Payment mode"
                value={PAYMENT_LABEL[data.paymentMode] ?? '—'}
              />
              <MetaRow
                label="Payment status"
                value={data.paymentStatus === 2 ? 'PAID' : 'Pending — COD'}
                tone={data.paymentStatus === 2 ? 'green' : 'amber'}
              />
            </div>
          </div>
        </section>

        {/* 3. BILL TO + SHIP TO ─────────────────────────────────────────────── */}
        <section className="px-10 py-5 grid grid-cols-2 gap-6">
          <AddressPanel label="Bill to" data={data} />
          <AddressPanel label="Ship to" data={data} />
        </section>

        {/* 4. LINE ITEMS TABLE ──────────────────────────────────────────────── */}
        <section className="px-10">
          <table className="w-full border-collapse text-[9.5pt]">
            <thead>
              <tr className="bg-stone-900 text-white text-[8pt] uppercase tracking-widest">
                <th className="text-left  py-2 px-3 font-medium w-10">#</th>
                <th className="text-left  py-2 px-3 font-medium">Description</th>
                <th className="text-left  py-2 px-3 font-medium w-20">HSN/SAC</th>
                <th className="text-right py-2 px-3 font-medium w-14">Qty</th>
                <th className="text-right py-2 px-3 font-medium w-24">Unit (₹)</th>
                <th className="text-right py-2 px-3 font-medium w-28">Amount (₹)</th>
              </tr>
            </thead>
            <tbody>
              <tr className="border-b border-stone-200">
                <td className="py-3 px-3 text-stone-500 align-top">1</td>
                <td className="py-3 px-3 align-top">
                  <p className="font-semibold text-stone-900">{data.productName}</p>
                  {(data.color || data.size || data.variantSku) && (
                    <p className="text-stone-500 text-[9pt] mt-0.5">
                      {[data.size && `Size ${data.size}`, data.color, data.variantSku].filter(Boolean).join(' · ')}
                    </p>
                  )}
                </td>
                <td className="py-3 px-3 font-mono text-stone-700 align-top">{hsnDefault}</td>
                <td className="py-3 px-3 text-right tabular-nums align-top">{data.quantity}</td>
                <td className="py-3 px-3 text-right tabular-nums align-top">
                  {data.unitPrice.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </td>
                <td className="py-3 px-3 text-right tabular-nums align-top font-semibold">
                  {itemSubtotal.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </td>
              </tr>
            </tbody>
          </table>
        </section>

        {/* 5. TOTALS — GST split based on inter/intra-state ─────────────────── */}
        <section className="px-10 mt-4 flex justify-end">
          <table className="text-[10pt]" style={{ minWidth: '80mm' }}>
            <tbody>
              <TotalRow label="Subtotal" amount={itemSubtotal} />
              {intrastate ? (
                <>
                  <TotalRow label="CGST" amount={cgst} subtle />
                  <TotalRow label="SGST" amount={sgst} subtle />
                </>
              ) : (
                <TotalRow label="IGST" amount={igst} subtle />
              )}
              <tr className="border-t-2 border-stone-900">
                <td className="py-2 pr-8 font-bold uppercase tracking-wider text-[10pt]">Grand total</td>
                <td className="py-2 text-right font-bold text-[14pt] tabular-nums">
                  ₹{grand.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                </td>
              </tr>
            </tbody>
          </table>
        </section>

        {/* 6. AMOUNT IN WORDS ──────────────────────────────────────────────── */}
        <section className="px-10 mt-3">
          <div className="bg-stone-50 border-l-4 border-brand-500 px-4 py-2 text-[9.5pt]">
            <span className="text-stone-500 text-[8pt] uppercase tracking-widest mr-2">Amount in words</span>
            <span className="font-semibold text-stone-900">
              {amountInWords(grand)}
            </span>
          </div>
        </section>

        {/* 7. SIGNATORY + DECLARATION ──────────────────────────────────────── */}
        <section className="px-10 mt-8 grid grid-cols-[1fr_auto] gap-8 items-end">
          <div className="text-[8.5pt] text-stone-600 leading-relaxed">
            <p className="font-semibold text-stone-800 mb-1">Declaration</p>
            <p>
              We declare that this invoice shows the actual price of the goods described and that
              all particulars are true and correct. Goods once sold are accepted for return only
              under the StopNShop returns policy within 7 days of delivery.
            </p>
          </div>
          <div className="text-center">
            <div className="border-b border-stone-400 w-44 h-10" />
            <p className="text-[8pt] uppercase tracking-widest text-stone-500 mt-1.5">Authorised signatory</p>
            <p className="text-[9pt] font-semibold text-stone-700">for {data.sellerBusinessName ?? 'Seller'}</p>
          </div>
        </section>

        {/* 8. FOOTER — Terms ─────────────────────────────────────────────── */}
        <footer className="mt-10 border-t border-stone-200 px-10 py-4 text-[7.5pt] text-stone-500 leading-relaxed">
          <div className="flex justify-between gap-6">
            <div className="flex-1">
              <p className="font-bold text-stone-700 text-[8pt] uppercase tracking-widest mb-1">Terms &amp; Conditions</p>
              <ul className="list-disc list-inside space-y-0.5">
                <li>This is an electronically generated invoice and does not require a physical signature.</li>
                <li>For returns, contact {data.sellerSupportEmail ?? 'support'} citing order {data.orderNumber} within 7 days.</li>
                <li>Subject to Mumbai jurisdiction. E. &amp; O. E.</li>
              </ul>
            </div>
            <div className="text-right flex-shrink-0">
              <p>Page 1 of 1</p>
              <p className="mt-0.5 font-mono">{invoiceNumber}</p>
            </div>
          </div>
        </footer>
      </div>
    </article>
  );
};

// ────────────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────────────

const MetaRow: React.FC<{
  label: string;
  value: string;
  mono?: boolean;
  tone?: 'green' | 'amber';
}> = ({ label, value, mono, tone }) => (
  <div className="flex items-baseline justify-between gap-3 py-0.5">
    <span className="text-stone-500 text-[8pt] uppercase tracking-widest">{label}</span>
    <span className={`${mono ? 'font-mono' : ''} font-semibold ${
      tone === 'green' ? 'text-emerald-700' : tone === 'amber' ? 'text-amber-700' : 'text-stone-900'
    }`}>
      {value}
    </span>
  </div>
);

const AddressPanel: React.FC<{ label: string; data: SellerLabelData }> = ({ label, data }) => (
  <div className="border border-stone-200 rounded-lg overflow-hidden">
    <p className="bg-stone-100 text-stone-700 text-[8pt] uppercase tracking-widest font-bold px-3 py-1.5">{label}</p>
    <div className="p-3 text-[9.5pt] leading-snug">
      <p className="font-bold text-stone-900">{data.buyerName ?? 'Customer'}</p>
      {data.addressLine1 && <p className="text-stone-700">{data.addressLine1}</p>}
      {data.addressLine2 && <p className="text-stone-700">{data.addressLine2}</p>}
      <p className="text-stone-700">
        {[data.buyerCity, data.buyerState, data.buyerPincode].filter(Boolean).join(', ')}
      </p>
      {data.buyerPhoneMasked && (
        <p className="text-stone-500 mt-1 text-[9pt] font-mono">{data.buyerPhoneMasked}</p>
      )}
    </div>
  </div>
);

const TotalRow: React.FC<{ label: string; amount: number; subtle?: boolean }> = ({ label, amount, subtle }) => (
  <tr>
    <td className={`py-1 pr-8 ${subtle ? 'text-stone-600' : 'font-medium text-stone-800'}`}>{label}</td>
    <td className="py-1 text-right tabular-nums">
      {amount.toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
    </td>
  </tr>
);

// ────────────────────────────────────────────────────────────────────────────
// Amount-in-words (Indian numbering: lakh / crore)
// ────────────────────────────────────────────────────────────────────────────

const ONES = ['Zero','One','Two','Three','Four','Five','Six','Seven','Eight','Nine','Ten',
              'Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen','Eighteen','Nineteen'];
const TENS = ['', '', 'Twenty','Thirty','Forty','Fifty','Sixty','Seventy','Eighty','Ninety'];

function twoDigit(n: number): string {
  if (n < 20) return ONES[n];
  const t = Math.floor(n / 10);
  const o = n % 10;
  return TENS[t] + (o ? ' ' + ONES[o] : '');
}

function threeDigit(n: number): string {
  const h = Math.floor(n / 100);
  const r = n % 100;
  const head = h ? `${ONES[h]} Hundred` : '';
  if (h && r) return `${head} ${twoDigit(r)}`;
  return head || twoDigit(r);
}

function intToIndianWords(n: number): string {
  if (n === 0) return 'Zero';
  const crore = Math.floor(n / 10_000_000);
  const lakh  = Math.floor((n % 10_000_000) / 100_000);
  const thou  = Math.floor((n % 100_000) / 1000);
  const rest  = n % 1000;
  const parts: string[] = [];
  if (crore) parts.push(`${threeDigit(crore)} Crore`);
  if (lakh)  parts.push(`${threeDigit(lakh)} Lakh`);
  if (thou)  parts.push(`${threeDigit(thou)} Thousand`);
  if (rest)  parts.push(threeDigit(rest));
  return parts.join(' ');
}

function amountInWords(amount: number): string {
  const rounded = Math.round(amount * 100) / 100;
  const rupees  = Math.floor(rounded);
  const paise   = Math.round((rounded - rupees) * 100);
  let s = `Rupees ${intToIndianWords(rupees)}`;
  if (paise) s += ` and ${twoDigit(paise)} Paise`;
  return s + ' Only';
}
