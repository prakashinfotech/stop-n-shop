import { describe, it, expect } from 'vitest';
import { MOVEMENT_TYPE_LABELS } from './inventoryApi';

/**
 * Lightweight Vitest coverage for the inventory module.
 * Component-level tests are deferred to Phase 5 (no jsdom/RTL setup on main).
 */
describe('inventory MOVEMENT_TYPE_LABELS', () => {
  it('maps every defined movement type (1..8) to a non-empty label', () => {
    for (let t = 1; t <= 8; t++) {
      expect(MOVEMENT_TYPE_LABELS[t]).toBeDefined();
      expect(MOVEMENT_TYPE_LABELS[t]).not.toBe('');
    }
  });

  it('labels reservation operations distinctly from ship/return', () => {
    expect(MOVEMENT_TYPE_LABELS[3]).toBe('Reserve');
    expect(MOVEMENT_TYPE_LABELS[4]).toBe('Release');
    expect(MOVEMENT_TYPE_LABELS[5]).toBe('Ship');
    expect(MOVEMENT_TYPE_LABELS[6]).toBe('Return');
  });

  it('distinguishes transfer-in from transfer-out', () => {
    expect(MOVEMENT_TYPE_LABELS[7]).toBe('Transfer Out');
    expect(MOVEMENT_TYPE_LABELS[8]).toBe('Transfer In');
  });
});
