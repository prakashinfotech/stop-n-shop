import React from 'react';
import { Check, AlertTriangle } from 'lucide-react';

export type StepStatus = 'pending' | 'valid' | 'error';

interface Step {
  label: string;
  status?: StepStatus;   // computed by the caller; defaults to 'pending'
}

interface StepperProps {
  steps: Step[];
  activeStep: number;
  /** Called when the user clicks a step header. The caller decides whether to honor it. */
  onStepClick?: (stepIndex: number) => void;
  /** When true, a step is clickable if its status is 'valid' OR it's before the active step. */
  allowForwardJump?: boolean;
}

export const Stepper: React.FC<StepperProps> = ({ steps, activeStep, onStepClick, allowForwardJump = false }) => (
  <div className="flex items-center">
    {steps.map((step, i) => {
      const active = i === activeStep;
      const visited = i < activeStep;
      const status: StepStatus = step.status ?? 'pending';
      const isError = status === 'error';
      const isValid = status === 'valid';

      const clickable = !active && (
        visited ||
        (allowForwardJump && isValid)
      );

      // Circle palette
      let circle = 'bg-surface-elevated border-outline-strong text-content-subtle';
      if (active && isError)      circle = 'bg-red-50 border-red-500 text-red-600';
      else if (active)            circle = 'bg-green-600 border-green-600 text-white';
      else if (isError)           circle = 'bg-red-50 border-red-400 text-red-600';
      else if (isValid)           circle = 'bg-green-600 border-green-600 text-white';

      // Label palette
      let labelTone = 'text-content-subtle';
      if (isError)      labelTone = 'text-red-600';
      else if (isValid || active) labelTone = 'text-green-600';

      return (
        <React.Fragment key={step.label}>
          <button
            type="button"
            onClick={() => clickable && onStepClick?.(i)}
            disabled={!clickable}
            className="flex flex-col items-center disabled:cursor-default hover:disabled:opacity-100 hover:opacity-80 transition-opacity"
          >
            <div
              className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-semibold border-2 transition-colors ${circle} ${clickable ? 'cursor-pointer' : ''}`}
              aria-current={active ? 'step' : undefined}
            >
              {isError && !active ? <AlertTriangle className="h-4 w-4" />
                : isValid && !active ? <Check className="h-4 w-4" />
                : i + 1}
            </div>
            <span className={`mt-1.5 text-xs font-medium whitespace-nowrap ${labelTone}`}>
              {step.label}
            </span>
          </button>
          {i < steps.length - 1 && (
            <div
              className={`flex-1 h-0.5 mx-2 mb-4 transition-colors ${
                isValid || i < activeStep ? 'bg-green-600' : 'bg-surface-sunken'
              }`}
            />
          )}
        </React.Fragment>
      );
    })}
  </div>
);
