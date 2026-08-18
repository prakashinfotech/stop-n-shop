import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';

interface Props {
  eyebrow?: string;
  title: string;
  subtitle?: string;
  actionHref?: string;
  actionLabel?: string;
}

/**
 * Consistent home-rail header: brand-red eyebrow tag, display-font title with a
 * small under-rule, optional subtitle, optional "See all" CTA that aligns to the
 * right on desktop and stacks below on mobile.
 */
export const SectionHeader: React.FC<Props> = ({ eyebrow, title, subtitle, actionHref, actionLabel = 'See all' }) => (
  <header className="flex items-end justify-between gap-4 mb-6">
    <div className="min-w-0">
      {eyebrow && (
        <p className="text-[11px] font-semibold text-brand-500 uppercase tracking-[0.18em] mb-1.5">
          {eyebrow}
        </p>
      )}
      <h2 className="font-display text-2xl sm:text-3xl font-bold text-content leading-tight">
        {title}
      </h2>
      <span className="block mt-2 h-[3px] w-10 bg-brand-500 rounded-full" aria-hidden />
      {subtitle && (
        <p className="text-sm text-content-muted mt-3 max-w-xl">{subtitle}</p>
      )}
    </div>
    {actionHref && (
      <Link
        to={actionHref}
        className="hidden sm:inline-flex items-center gap-1 text-sm font-semibold text-content hover:text-brand-500 transition-colors flex-shrink-0"
      >
        {actionLabel}
        <ArrowRight className="h-3.5 w-3.5" />
      </Link>
    )}
  </header>
);
