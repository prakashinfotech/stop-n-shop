import React, { useEffect, useRef } from 'react';
import bwipjs from 'bwip-js/browser';

interface Props {
  value: string;
  type?: 'code128' | 'qrcode';
  scale?: number;
  height?: number;   // for 1D barcodes (in module units)
}

/**
 * Renders a barcode or QR code to a <canvas> using bwip-js (pure JS, no server).
 * Safe to print — canvases are pixel data that survive window.print().
 */
export const Barcode: React.FC<Props> = ({ value, type = 'code128', scale = 2, height = 12 }) => {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    if (!ref.current) return;
    try {
      bwipjs.toCanvas(ref.current, {
        bcid:       type,
        text:       value,
        scale,
        height:     type === 'qrcode' ? undefined : height,
        includetext: type === 'code128',
        textxalign: 'center',
        textsize:   8,
        backgroundcolor: 'FFFFFF',
      });
    } catch {
      /* bwip-js throws on invalid text — render an empty canvas */
    }
  }, [value, type, scale, height]);

  return <canvas ref={ref} aria-label={`${type} ${value}`} />;
};
