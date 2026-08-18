import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Award, Activity } from 'lucide-react';
import { sellerLifecycleApi } from '../../../api/sellerLifecycleApi';

const tierClass: Record<string, string> = {
  Platinum: 'bg-indigo-50 text-indigo-700 border-indigo-200',
  Gold:     'bg-amber-50 text-amber-700 border-amber-200',
  Silver:   'bg-surface-sunken text-content border-outline',
  Bronze:   'bg-orange-50 text-orange-700 border-orange-200',
};

export const PerformanceScoreCard: React.FC = () => {
  const { data, isLoading } = useQuery({
    queryKey: ['seller-performance-score'],
    queryFn: () => sellerLifecycleApi.performanceScore.get().then(r => r.data.data),
    staleTime: 1000 * 60 * 10,
  });

  if (isLoading) {
    return <div className="bg-surface-elevated rounded-xl p-6 border border-outline/60 animate-pulse h-40" />;
  }
  if (!data) {
    return (
      <div className="bg-surface-elevated rounded-xl p-6 border border-outline/60">
        <h2 className="text-base font-semibold text-content mb-2 flex items-center gap-2">
          <Activity size={16} /> Performance Score
        </h2>
        <p className="text-sm text-content-muted">No score yet — the nightly worker will publish your first snapshot after 24 hours.</p>
      </div>
    );
  }

  return (
    <div className="bg-surface-elevated rounded-xl p-6 border border-outline/60">
      <div className="flex items-start justify-between mb-4">
        <h2 className="text-base font-semibold text-content flex items-center gap-2">
          <Award size={16} /> Performance Score
        </h2>
        <span className={`px-2.5 py-1 rounded-full text-xs font-medium border ${tierClass[data.tier] ?? tierClass.Bronze}`}>
          {data.tier}
        </span>
      </div>

      <div className="mb-4">
        <div className="flex items-end gap-2">
          <span className="text-4xl font-bold text-content">{data.compositeScore.toFixed(1)}</span>
          <span className="text-content-subtle mb-1">/ 100</span>
        </div>
        <div className="mt-2 w-full h-2 bg-surface-sunken rounded-full overflow-hidden">
          <div className="h-full bg-gradient-brand" style={{ width: `${Math.min(100, Math.max(0, data.compositeScore))}%` }} />
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 text-xs">
        <div>
          <p className="text-content-muted">On-time dispatch</p>
          <p className="font-semibold text-content">{data.onTimeDispatchPct.toFixed(1)}%</p>
        </div>
        <div>
          <p className="text-content-muted">Cancellation rate</p>
          <p className="font-semibold text-content">{data.cancellationPct.toFixed(1)}%</p>
        </div>
        <div>
          <p className="text-content-muted">Return rate</p>
          <p className="font-semibold text-content">{data.returnPct.toFixed(1)}%</p>
        </div>
        <div>
          <p className="text-content-muted">Avg rating</p>
          <p className="font-semibold text-content">{data.avgRating.toFixed(2)} / 5</p>
        </div>
      </div>

      <p className="text-xs text-content-subtle mt-4">
        Rolling {data.windowDays}-day window · snapshot {new Date(data.snapshotDate).toLocaleDateString('en-IN')}
      </p>
    </div>
  );
};
