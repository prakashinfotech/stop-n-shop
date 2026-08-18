import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { KpiCard } from '../KpiCard';

describe('KpiCard', () => {
  it('renders label, value, and hint', () => {
    render(<KpiCard label="Total Orders" value={42} hint="last 30 days" />);
    expect(screen.getByText('Total Orders')).toBeInTheDocument();
    expect(screen.getByText('42')).toBeInTheDocument();
    expect(screen.getByText('last 30 days')).toBeInTheDocument();
  });

  it('applies tone styling', () => {
    const { container } = render(<KpiCard label="Errors" value="3" tone="danger" />);
    const card = container.firstChild as HTMLElement;
    expect(card.className).toContain('bg-rose-50');
  });
});
