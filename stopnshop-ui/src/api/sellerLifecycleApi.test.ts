import { describe, it, expect } from 'vitest';
import { SETTLEMENT_STATUS_LABELS } from './sellerLifecycleApi';

describe('SETTLEMENT_STATUS_LABELS', () => {
  it('maps the four documented statuses', () => {
    expect(SETTLEMENT_STATUS_LABELS[1]).toBe('Pending');
    expect(SETTLEMENT_STATUS_LABELS[2]).toBe('Paid');
    expect(SETTLEMENT_STATUS_LABELS[3]).toBe('On Hold');
    expect(SETTLEMENT_STATUS_LABELS[4]).toBe('Failed');
  });

  it('returns undefined for unknown statuses', () => {
    expect(SETTLEMENT_STATUS_LABELS[0]).toBeUndefined();
    expect(SETTLEMENT_STATUS_LABELS[99]).toBeUndefined();
  });
});
