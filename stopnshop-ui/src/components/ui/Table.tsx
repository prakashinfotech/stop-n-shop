import React from 'react';
import { clsx } from 'clsx';

/**
 * Lightweight table primitives. Separation is achieved through surface-tone
 * difference (cream header on cream body) rather than hard 1px borders, in
 * keeping with the Claude.ai aesthetic.
 *
 * Usage:
 *   <Table>
 *     <THead>
 *       <TR><TH>Order</TH><TH>Status</TH></TR>
 *     </THead>
 *     <TBody>
 *       <TR><TD>#1</TD><TD>Pending</TD></TR>
 *     </TBody>
 *   </Table>
 */

export const Table: React.FC<React.TableHTMLAttributes<HTMLTableElement>> = ({
  className, children, ...props
}) => (
  <div className="bg-surface-elevated rounded-2xl shadow-soft overflow-hidden">
    <div className="overflow-x-auto">
      <table className={clsx('w-full text-left border-collapse', className)} {...props}>
        {children}
      </table>
    </div>
  </div>
);

export const THead: React.FC<React.HTMLAttributes<HTMLTableSectionElement>> = ({
  className, children, ...props
}) => (
  <thead className={clsx('bg-surface', className)} {...props}>{children}</thead>
);

export const TBody: React.FC<React.HTMLAttributes<HTMLTableSectionElement>> = ({
  className, children, ...props
}) => (
  <tbody className={clsx('divide-y divide-outline/60', className)} {...props}>{children}</tbody>
);

export const TR: React.FC<React.HTMLAttributes<HTMLTableRowElement> & { hoverable?: boolean }> = ({
  className, hoverable = true, children, ...props
}) => (
  <tr
    className={clsx(hoverable && 'hover:bg-surface/60 transition-colors', className)}
    {...props}
  >
    {children}
  </tr>
);

export const TH: React.FC<React.ThHTMLAttributes<HTMLTableCellElement>> = ({
  className, children, ...props
}) => (
  <th
    className={clsx(
      'px-6 py-3.5 text-xs font-semibold uppercase tracking-wider text-content-muted',
      className,
    )}
    {...props}
  >
    {children}
  </th>
);

export const TD: React.FC<React.TdHTMLAttributes<HTMLTableCellElement>> = ({
  className, children, ...props
}) => (
  <td className={clsx('px-6 py-4 text-sm text-content', className)} {...props}>
    {children}
  </td>
);
