import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Printer, Loader2 } from 'lucide-react';
import { sellerLabelApi } from '../../../api/sellerLabelApi';
import { ShippingSticker } from './ShippingSticker';
import { OrderReceipt }    from './OrderReceipt';

type Mode = 'both' | 'sticker' | 'receipt';

/**
 * Print page for a confirmed order item. Renders both the sticker and the
 * receipt; the seller picks which one(s) to send to the printer via the mode
 * dropdown. Uses the browser's native print dialog — they can save as PDF
 * from there for record-keeping.
 */
export const PrintLabelPage: React.FC = () => {
  const { itemId } = useParams<{ itemId: string }>();
  const id = Number(itemId);
  const [mode, setMode] = useState<Mode>('both');

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ['label-data', id],
    queryFn: () => sellerLabelApi.getLabelData(id).then((r) => r.data.data!),
    enabled: !!id,
  });

  // Reflect the mode in a body class so the @media print stylesheet hides
  // whichever artefact the seller doesn't want to print.
  useEffect(() => {
    document.body.classList.remove('print-mode-both', 'print-mode-sticker', 'print-mode-receipt');
    document.body.classList.add(`print-mode-${mode}`);
    return () => {
      document.body.classList.remove('print-mode-both', 'print-mode-sticker', 'print-mode-receipt');
    };
  }, [mode]);

  return (
    <div className="min-h-screen bg-stone-100">
      {/* Toolbar — hidden when printing */}
      <header className="no-print sticky top-0 z-10 bg-white border-b border-stone-200 px-6 py-3 flex items-center justify-between">
        <Link to="/seller/orders/queue"
              className="inline-flex items-center gap-1.5 text-sm text-stone-600 hover:text-stone-900">
          <ArrowLeft className="h-4 w-4" /> Back to queue
        </Link>
        <div className="flex items-center gap-3">
          <label className="text-xs text-stone-500">Print</label>
          <select value={mode} onChange={(e) => setMode(e.target.value as Mode)}
                  className="text-sm border border-stone-300 rounded-lg px-2 py-1 bg-white">
            <option value="both">Sticker + Receipt</option>
            <option value="sticker">Sticker only</option>
            <option value="receipt">Receipt only</option>
          </select>
          <button
            onClick={() => window.print()}
            disabled={!data}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-brand-500 text-white text-sm font-medium hover:bg-brand-600 disabled:opacity-50"
          >
            <Printer className="h-4 w-4" /> Print
          </button>
        </div>
      </header>

      {/* Body */}
      <main className="py-8 px-4 space-y-8">
        {isLoading && (
          <div className="text-center text-stone-500 py-16">
            <Loader2 className="h-6 w-6 animate-spin mx-auto mb-2" />
            Preparing label…
          </div>
        )}
        {isError && (
          <div className="max-w-md mx-auto bg-white border border-red-200 rounded-xl p-6 text-center">
            <p className="font-semibold text-red-700">Couldn't load label</p>
            <p className="text-sm text-stone-600 mt-1">
              {(error as any)?.response?.data?.message ?? 'Make sure the item is confirmed first.'}
            </p>
            <Link to="/seller/orders/queue" className="text-brand-500 text-sm font-medium mt-3 inline-block">
              ← Back to queue
            </Link>
          </div>
        )}
        {data && (
          <>
            <section className="print-sticker shadow-lg">
              <ShippingSticker data={data} />
            </section>
            <section className="print-receipt shadow-lg">
              <OrderReceipt data={data} />
            </section>
          </>
        )}
      </main>
    </div>
  );
};
