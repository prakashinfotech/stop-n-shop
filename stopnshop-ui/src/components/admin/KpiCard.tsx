import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowUpRight } from 'lucide-react';

interface KpiCardProps {
  label: string;
  value: React.ReactNode;
  hint?: string;
  icon?: React.ReactNode;
  tone?: 'default' | 'positive' | 'warning' | 'danger';
  /** When set, the entire card becomes a click-through link with the given route. */
  href?: string;
}

const toneClasses: Record<Required<KpiCardProps>['tone'], string> = {
  default:  'bg-surface-elevated border-outline text-content',
  positive: 'bg-emerald-50 border-emerald-200 text-emerald-900',
  warning:  'bg-amber-50 border-amber-200 text-amber-900',
  danger:   'bg-rose-50 border-rose-200 text-rose-900',
};

export const KpiCard: React.FC<KpiCardProps> = ({ label, value, hint, icon, tone = 'default', href }) => {
  const body = (
    <>
      <div className="flex items-start justify-between">
        <div className="text-xs uppercase tracking-wide opacity-70">{label}</div>
        {icon
          ? <div className="opacity-60">{icon}</div>
          : href && <ArrowUpRight className="h-4 w-4 opacity-40 group-hover:opacity-80 transition-opacity" />}
      </div>
      <div className="mt-2 text-2xl font-semibold leading-tight">{value}</div>
      {hint && <div className="mt-1 text-xs opacity-60">{hint}</div>}
    </>
  );

  const base = `rounded-xl border p-4 shadow-sm ${toneClasses[tone]}`;

  if (href) {
    return (
      <Link
        to={href}
        aria-label={`${label}: ${typeof value === 'string' || typeof value === 'number' ? value : ''} — open list`}
        className={`group block transition-shadow hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-300 ${base}`}
      >
        {body}
      </Link>
    );
  }
  return <div className={base}>{body}</div>;
};
