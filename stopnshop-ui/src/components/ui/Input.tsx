import React, { forwardRef } from 'react';
import { clsx } from 'clsx';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  hint?: string;
  error?: string;
  leftAddon?: React.ReactNode;
  rightAddon?: React.ReactNode;
  containerClassName?: string;
}

const FIELD_BASE =
  'w-full bg-surface-sunken text-content placeholder:text-content-subtle ' +
  'border border-transparent rounded-xl px-4 py-2.5 text-sm ' +
  'transition-colors focus:outline-none focus:bg-surface-elevated ' +
  'focus:border-brand-400 focus:ring-2 focus:ring-brand-200/40 ' +
  'disabled:opacity-60 disabled:cursor-not-allowed';

export const Input = forwardRef<HTMLInputElement, InputProps>(({
  label, hint, error, leftAddon, rightAddon,
  containerClassName, className, id, ...props
}, ref) => {
  const fieldId = id ?? props.name;
  return (
    <div className={clsx('w-full', containerClassName)}>
      {label && (
        <label htmlFor={fieldId} className="block text-sm font-medium text-content mb-1.5">
          {label}
        </label>
      )}
      <div className="relative">
        {leftAddon && (
          <div className="absolute left-3 top-1/2 -translate-y-1/2 text-content-subtle">
            {leftAddon}
          </div>
        )}
        <input
          ref={ref}
          id={fieldId}
          className={clsx(
            FIELD_BASE,
            leftAddon && 'pl-10',
            rightAddon && 'pr-10',
            error && 'border-red-400 focus:border-red-500 focus:ring-red-200/40',
            className,
          )}
          {...props}
        />
        {rightAddon && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle">
            {rightAddon}
          </div>
        )}
      </div>
      {error ? (
        <p className="mt-1.5 text-xs text-red-600">{error}</p>
      ) : hint ? (
        <p className="mt-1.5 text-xs text-content-subtle">{hint}</p>
      ) : null}
    </div>
  );
});
Input.displayName = 'Input';

interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  hint?: string;
  error?: string;
  containerClassName?: string;
}

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(({
  label, hint, error, containerClassName, className, id, ...props
}, ref) => {
  const fieldId = id ?? props.name;
  return (
    <div className={clsx('w-full', containerClassName)}>
      {label && (
        <label htmlFor={fieldId} className="block text-sm font-medium text-content mb-1.5">
          {label}
        </label>
      )}
      <textarea
        ref={ref}
        id={fieldId}
        className={clsx(
          FIELD_BASE,
          'resize-none',
          error && 'border-red-400 focus:border-red-500 focus:ring-red-200/40',
          className,
        )}
        {...props}
      />
      {error ? (
        <p className="mt-1.5 text-xs text-red-600">{error}</p>
      ) : hint ? (
        <p className="mt-1.5 text-xs text-content-subtle">{hint}</p>
      ) : null}
    </div>
  );
});
Textarea.displayName = 'Textarea';

interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  hint?: string;
  error?: string;
  containerClassName?: string;
  children: React.ReactNode;
}

export const Select = forwardRef<HTMLSelectElement, SelectProps>(({
  label, hint, error, containerClassName, className, id, children, ...props
}, ref) => {
  const fieldId = id ?? props.name;
  return (
    <div className={clsx('w-full', containerClassName)}>
      {label && (
        <label htmlFor={fieldId} className="block text-sm font-medium text-content mb-1.5">
          {label}
        </label>
      )}
      <select
        ref={ref}
        id={fieldId}
        className={clsx(
          FIELD_BASE,
          'cursor-pointer pr-10 appearance-none bg-[length:1rem] bg-no-repeat bg-[right_0.75rem_center]',
          error && 'border-red-400 focus:border-red-500 focus:ring-red-200/40',
          className,
        )}
        style={{
          backgroundImage:
            "url(\"data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%2378716c' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='6 9 12 15 18 9'/></svg>\")",
        }}
        {...props}
      >
        {children}
      </select>
      {error ? (
        <p className="mt-1.5 text-xs text-red-600">{error}</p>
      ) : hint ? (
        <p className="mt-1.5 text-xs text-content-subtle">{hint}</p>
      ) : null}
    </div>
  );
});
Select.displayName = 'Select';
