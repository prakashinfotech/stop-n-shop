import React, { useState } from 'react';
import { DEFAULT_PRODUCT_IMAGE } from '../../constants/productImage';

type SafeImageProps = React.ImgHTMLAttributes<HTMLImageElement> & {
  fallback?: string;
};

export const SafeImage: React.FC<SafeImageProps> = ({ src, fallback = DEFAULT_PRODUCT_IMAGE, alt = '', onError, ...rest }) => {
  const initial = src && String(src).trim().length > 0 ? String(src) : fallback;
  const [current, setCurrent] = useState(initial);

  return (
    <img
      {...rest}
      src={current}
      alt={alt}
      onError={(e) => {
        if (current !== fallback) setCurrent(fallback);
        onError?.(e);
      }}
    />
  );
};
