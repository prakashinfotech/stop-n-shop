import React from 'react';
import { Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Search, X } from 'lucide-react';
import { engagementApi } from '../../api/engagementApi';
import { useAuthContext } from '../../context/AuthContext';
import { SectionHeader } from './SectionHeader';

/**
 * Renders the buyer's last few distinct search terms as click-to-revisit chips.
 * Hidden entirely for unauthenticated users (the endpoint returns [] in that case
 * but rendering an empty rail is worse than rendering nothing). Local-storage
 * dismissal lets the buyer hide individual terms without a round-trip.
 */
const DISMISSED_KEY = 'sns_recent_searches_dismissed';

export const RecentSearches: React.FC = () => {
  const { isAuthenticated } = useAuthContext();

  const { data: terms = [] } = useQuery({
    queryKey: ['engagement', 'recent-searches'],
    queryFn: () => engagementApi.getRecentSearches(6).then((r) => r.data.data ?? []),
    enabled: isAuthenticated,
    staleTime: 1000 * 60,
  });

  const [dismissed, setDismissed] = React.useState<string[]>(() => {
    try {
      const raw = typeof window !== 'undefined' ? window.localStorage.getItem(DISMISSED_KEY) : null;
      return raw ? (JSON.parse(raw) as string[]) : [];
    } catch { return []; }
  });

  React.useEffect(() => {
    try { window.localStorage.setItem(DISMISSED_KEY, JSON.stringify(dismissed)); } catch { /* ignore */ }
  }, [dismissed]);

  const visible = terms.filter((t) => !dismissed.includes(t.toLowerCase()));
  if (!isAuthenticated || visible.length === 0) return null;

  return (
    <section className="w-full px-4 sm:px-6 lg:px-8 py-8">
      <SectionHeader
        eyebrow="Pick up where you left off"
        title="Recently Searched"
        subtitle="Jump back into a search you ran earlier."
      />

      <div className="flex flex-wrap gap-2">
        {visible.map((term) => (
          <span
            key={term}
            className="group inline-flex items-center gap-1 pl-1 pr-1 py-1 rounded-full bg-surface-elevated border border-outline hover:border-brand-300 hover:bg-brand-50/40 text-sm text-content transition-colors"
          >
            <Link
              to={`/home/products?search=${encodeURIComponent(term)}`}
              className="inline-flex items-center gap-1.5 px-2 py-0.5"
            >
              <Search className="h-3.5 w-3.5 text-content-muted group-hover:text-brand-500" />
              <span className="font-medium">{term}</span>
            </Link>
            <button
              type="button"
              onClick={() => setDismissed((d) => [...d, term.toLowerCase()])}
              aria-label={`Remove ${term} from recent searches`}
              className="p-1 rounded-full text-content-subtle hover:text-red-600 hover:bg-red-50 transition-colors"
            >
              <X className="h-3 w-3" />
            </button>
          </span>
        ))}
      </div>
    </section>
  );
};
