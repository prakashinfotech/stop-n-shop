import React, { useRef } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface HorizontalScrollProps {
  children: React.ReactNode;
  className?: string;
}

export const HorizontalScroll: React.FC<HorizontalScrollProps> = ({ children, className = '' }) => {
  const ref = useRef<HTMLDivElement>(null);

  const scroll = (direction: 'left' | 'right') => {
    if (!ref.current) return;
    const amount = ref.current.clientWidth * 0.7;
    ref.current.scrollBy({ left: direction === 'right' ? amount : -amount, behavior: 'smooth' });
  };

  return (
    // Named group "scroller" so the chevron-reveal only triggers off OUR hover,
    // not off any child component (e.g. ProductCard) that also uses `group`.
    // Unnamed `group` cascades — group-hover on a card would fire on every card
    // in the row because they all live under one ancestor `group`.
    <div className="relative group/scroller">
      <button
        onClick={() => scroll('left')}
        className="absolute left-0 top-1/2 -translate-y-1/2 -translate-x-3 z-10 bg-surface-elevated border border-outline shadow-md rounded-full p-1.5 text-content hover:bg-surface opacity-0 group-hover/scroller:opacity-100 transition-opacity hidden md:flex"
        aria-label="Scroll left"
      >
        <ChevronLeft className="h-4 w-4" />
      </button>

      <div
        ref={ref}
        className={`flex overflow-x-auto gap-4 pb-2 scroll-smooth hide-scrollbar ${className}`}
      >
        {children}
      </div>

      <button
        onClick={() => scroll('right')}
        className="absolute right-0 top-1/2 -translate-y-1/2 translate-x-3 z-10 bg-surface-elevated border border-outline shadow-md rounded-full p-1.5 text-content hover:bg-surface opacity-0 group-hover/scroller:opacity-100 transition-opacity hidden md:flex"
        aria-label="Scroll right"
      >
        <ChevronRight className="h-4 w-4" />
      </button>
    </div>
  );
};
