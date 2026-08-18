import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { Button } from '../Button';
import { Card, CardTitle, CardDescription } from '../Card';
import { Input, Textarea, Select } from '../Input';
import { Badge, orderStatusVariant } from '../Badge';
import { Modal } from '../Modal';
import { EmptyState } from '../EmptyState';
import { Skeleton, SkeletonRow, SkeletonCard } from '../Skeleton';
import { Table, THead, TBody, TR, TH, TD } from '../Table';

describe('Button', () => {
  it('renders all variants without crashing', () => {
    for (const v of ['primary','secondary','outline','ghost','danger','gold'] as const) {
      const { unmount } = render(<Button variant={v}>{v}</Button>);
      expect(screen.getByRole('button', { name: v })).toBeInTheDocument();
      unmount();
    }
  });
  it('disables while loading', () => {
    render(<Button isLoading>Go</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });
  it('fires onClick', () => {
    const onClick = vi.fn();
    render(<Button onClick={onClick}>Click</Button>);
    fireEvent.click(screen.getByRole('button'));
    expect(onClick).toHaveBeenCalledOnce();
  });
});

describe('Card', () => {
  it('renders title and description', () => {
    render(
      <Card>
        <CardTitle>Hello</CardTitle>
        <CardDescription>World</CardDescription>
      </Card>,
    );
    expect(screen.getByText('Hello')).toBeInTheDocument();
    expect(screen.getByText('World')).toBeInTheDocument();
  });
});

describe('Input / Textarea / Select', () => {
  it('Input shows label and error', () => {
    render(<Input label="Email" error="Required" name="email" />);
    expect(screen.getByLabelText('Email')).toBeInTheDocument();
    expect(screen.getByText('Required')).toBeInTheDocument();
  });
  it('Textarea forwards value changes', () => {
    const onChange = vi.fn();
    render(<Textarea label="Bio" name="bio" onChange={onChange} />);
    fireEvent.change(screen.getByLabelText('Bio'), { target: { value: 'hi' } });
    expect(onChange).toHaveBeenCalled();
  });
  it('Select renders options', () => {
    render(
      <Select label="Color" name="color" defaultValue="red">
        <option value="red">Red</option>
        <option value="blue">Blue</option>
      </Select>,
    );
    expect(screen.getByLabelText('Color')).toBeInTheDocument();
    expect(screen.getByRole('option', { name: 'Red' })).toBeInTheDocument();
  });
});

describe('Badge', () => {
  it('renders text', () => {
    render(<Badge variant="shipped" dot>Shipped</Badge>);
    expect(screen.getByText('Shipped')).toBeInTheDocument();
  });
  it('orderStatusVariant maps statuses', () => {
    expect(orderStatusVariant('Pending')).toBe('pending');
    expect(orderStatusVariant('SHIPPED')).toBe('shipped');
    expect(orderStatusVariant('Canceled')).toBe('cancelled');
    expect(orderStatusVariant(null)).toBe('neutral');
    expect(orderStatusVariant('whatever')).toBe('neutral');
  });
});

describe('Modal', () => {
  it('renders when open and closes on backdrop click', () => {
    const onClose = vi.fn();
    render(<Modal open onClose={onClose} title="Hi">body</Modal>);
    expect(screen.getByText('Hi')).toBeInTheDocument();
    expect(screen.getByText('body')).toBeInTheDocument();
    // backdrop is the first absolute div
    const dialog = screen.getByRole('dialog');
    fireEvent.click(dialog.querySelector('.absolute')!);
    expect(onClose).toHaveBeenCalled();
  });
  it('renders nothing when closed', () => {
    render(<Modal open={false} onClose={() => {}} title="Hi">body</Modal>);
    expect(screen.queryByText('Hi')).not.toBeInTheDocument();
  });
});

describe('EmptyState', () => {
  it('renders title, description and action', () => {
    render(
      <EmptyState
        title="No orders"
        description="Try again later"
        action={<button>Refresh</button>}
      />,
    );
    expect(screen.getByText('No orders')).toBeInTheDocument();
    expect(screen.getByText('Try again later')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Refresh' })).toBeInTheDocument();
  });
});

describe('Skeleton', () => {
  it('renders requested count', () => {
    const { container } = render(<Skeleton count={3} />);
    expect(container.querySelectorAll('.animate-pulse').length).toBe(3);
  });
  it('SkeletonRow renders cols', () => {
    const { container } = render(<SkeletonRow cols={5} />);
    expect(container.querySelectorAll('.animate-pulse').length).toBe(5);
  });
  it('SkeletonCard renders', () => {
    const { container } = render(<SkeletonCard />);
    expect(container.querySelectorAll('.animate-pulse').length).toBeGreaterThan(0);
  });
});

describe('Table', () => {
  it('renders header and body cells', () => {
    render(
      <Table>
        <THead><TR><TH>Name</TH></TR></THead>
        <TBody><TR><TD>Alice</TD></TR></TBody>
      </Table>,
    );
    expect(screen.getByText('Name')).toBeInTheDocument();
    expect(screen.getByText('Alice')).toBeInTheDocument();
  });
});
