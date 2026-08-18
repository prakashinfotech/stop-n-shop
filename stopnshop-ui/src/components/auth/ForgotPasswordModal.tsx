import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Mail, Lock, Eye, EyeOff, AlertCircle, CheckCircle2, ArrowRight, ArrowLeft, X } from 'lucide-react';
import { authApi } from '../../api/authApi';
import { useToast } from '../ui/Toast';
import { OtpInput } from './OtpInput';
import { useOtpTimer } from '../../hooks/useOtpTimer';

// ── Schemas ──────────────────────────────────────────────────────────────────

const emailSchema = z.object({
  email: z.string().email('Enter a valid email address'),
});
type EmailForm = z.infer<typeof emailSchema>;

const passwordSchema = z
  .object({
    newPassword: z
      .string()
      .min(8, 'At least 8 characters')
      .regex(/[A-Z]/, 'Add an uppercase letter')
      .regex(/[0-9]/, 'Add a number'),
    confirmPassword: z.string().min(1, 'Please confirm your password'),
  })
  .refine((d) => d.newPassword === d.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });
type PasswordForm = z.infer<typeof passwordSchema>;

const PASSWORD_RULES = [
  { label: 'At least 8 characters', test: (v: string) => v.length >= 8 },
  { label: 'One uppercase letter',  test: (v: string) => /[A-Z]/.test(v) },
  { label: 'One number',            test: (v: string) => /[0-9]/.test(v) },
];

// ── Props ────────────────────────────────────────────────────────────────────

interface ForgotPasswordModalProps {
  onClose: () => void;
}

// ── Component ────────────────────────────────────────────────────────────────

export const ForgotPasswordModal: React.FC<ForgotPasswordModalProps> = ({ onClose }) => {
  const [step, setStep]               = useState<'email' | 'otp' | 'password' | 'done'>('email');
  const [userId, setUserId]           = useState<number | null>(null);
  const [emailVal, setEmailVal]       = useState('');
  const [firstName, setFirstName]     = useState('');
  const [serverError, setServerError] = useState<string | null>(null);
  const [showNew, setShowNew]         = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  // OTP step state
  const [otp, setOtp]               = useState('');
  const [otpError, setOtpError]     = useState('');
  const { timer, isRunning, start: startTimer } = useOtpTimer(60);

  const { showToast } = useToast();

  // ── Email form ─────────────────────────────────────────────────────────────
  const emailForm = useForm<EmailForm>({ resolver: zodResolver(emailSchema), mode: 'onChange' });

  const onEmailSubmit = async (data: EmailForm) => {
    setServerError(null);
    try {
      const res = await authApi.forgotPassword(data.email);
      const result = res.data.data;
      if (result?.userId) {
        setUserId(result.userId);
        setEmailVal(data.email);
        setFirstName(result.firstName ?? '');
        setStep('otp');
        startTimer();
      } else {
        setStep('done');
      }
    } catch {
      setServerError('Something went wrong. Please try again.');
    }
  };

  // ── OTP step ───────────────────────────────────────────────────────────────
  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (otp.length !== 6) { setOtpError('Enter the 6-digit code'); return; }
    setOtpError('');
    setServerError(null);
    try {
      await authApi.verifyForgotPasswordOtp(userId!, otp);
      setStep('password');
    } catch {
      setOtpError('Invalid or expired OTP. Please try again.');
    }
  };

  const handleResendOtp = async () => {
    if (isRunning) return;
    setServerError(null);
    try {
      await authApi.forgotPassword(emailVal);
      startTimer();
      setOtp('');
      setOtpError('');
      showToast('OTP resent to your email');
    } catch {
      showToast('Could not resend OTP', 'error');
    }
  };

  // ── Password form ──────────────────────────────────────────────────────────
  const passwordForm = useForm<PasswordForm>({ resolver: zodResolver(passwordSchema), mode: 'onChange' });
  const newPasswordValue = passwordForm.watch('newPassword', '');

  const onPasswordSubmit = async (data: PasswordForm) => {
    if (!userId) return;
    setServerError(null);
    try {
      await authApi.resetPassword(userId, data.newPassword);
      setStep('done');
      showToast('Password reset successfully. You can now sign in.');
    } catch {
      setServerError('Password reset failed. Please try again.');
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      <div className="relative w-full max-w-md bg-surface-elevated rounded-2xl shadow-2xl overflow-hidden">

        <button
          onClick={onClose}
          className="absolute top-4 right-4 p-1.5 rounded-full text-content-subtle hover:text-content-muted hover:bg-surface-sunken transition-colors z-10"
          aria-label="Close"
        >
          <X className="h-4 w-4" />
        </button>

        <div className="p-8">

          {/* ── Step: Email ─────────────────────────────────────────── */}
          {step === 'email' && (
            <>
              <div className="mb-6">
                <div className="w-12 h-12 rounded-full bg-brand-50 flex items-center justify-center mb-4">
                  <Mail className="h-6 w-6 text-brand-500" />
                </div>
                <h2 className="font-display text-xl font-bold text-content mb-1">Forgot your password?</h2>
                <p className="text-sm text-content-muted">
                  Enter the email address linked to your account and we'll send you a verification code.
                </p>
              </div>

              {serverError && (
                <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-3 py-2.5 text-sm mb-4">
                  <AlertCircle className="h-4 w-4 flex-shrink-0" /> {serverError}
                </div>
              )}

              <form onSubmit={emailForm.handleSubmit(onEmailSubmit)} noValidate className="space-y-4">
                <div>
                  <label htmlFor="fp-email" className="block text-sm font-medium text-content mb-1.5">Email address</label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                    <input
                      id="fp-email"
                      type="email"
                      autoComplete="email"
                      placeholder="you@example.com"
                      {...emailForm.register('email')}
                      className={`w-full pl-10 pr-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                        emailForm.formState.errors.email ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                      }`}
                    />
                  </div>
                  {emailForm.formState.errors.email && (
                    <p className="mt-1.5 text-xs text-red-600 flex items-center gap-1">
                      <AlertCircle className="h-3 w-3" /> {emailForm.formState.errors.email.message}
                    </p>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={emailForm.formState.isSubmitting}
                  className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60"
                >
                  {emailForm.formState.isSubmitting ? 'Checking…' : <><span>Send OTP</span><ArrowRight className="h-4 w-4" /></>}
                </button>
              </form>
            </>
          )}

          {/* ── Step: OTP ───────────────────────────────────────────── */}
          {step === 'otp' && (
            <>
              <div className="mb-6">
                <button
                  type="button"
                  onClick={() => { setStep('email'); setOtp(''); setOtpError(''); setServerError(null); }}
                  className="flex items-center gap-1.5 text-sm text-content-muted hover:text-content mb-4 -ml-1"
                >
                  <ArrowLeft className="h-4 w-4" /> Back
                </button>
                <div className="w-12 h-12 rounded-full bg-brand-50 flex items-center justify-center mb-4">
                  <Mail className="h-6 w-6 text-brand-500" />
                </div>
                <h2 className="font-display text-xl font-bold text-content mb-1">Check your email</h2>
                <p className="text-sm text-content-muted">
                  We sent a 6-digit code to <span className="font-semibold text-content">{emailVal}</span>
                </p>
              </div>

              {serverError && (
                <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-3 py-2.5 text-sm mb-4">
                  <AlertCircle className="h-4 w-4 flex-shrink-0" /> {serverError}
                </div>
              )}

              <form onSubmit={handleVerifyOtp} noValidate className="space-y-4">
                <OtpInput value={otp} onChange={setOtp} hasError={!!otpError} />
                {otpError && (
                  <p className="text-xs text-red-600 flex items-center justify-center gap-1">
                    <AlertCircle className="h-3 w-3" /> {otpError}
                  </p>
                )}

                <div className="text-center text-xs">
                  {isRunning ? (
                    <span className="text-content-subtle">Resend in {timer}s</span>
                  ) : (
                    <button type="button" onClick={handleResendOtp} className="text-brand-500 hover:underline font-medium">
                      Resend OTP
                    </button>
                  )}
                </div>

                <button
                  type="submit"
                  className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors"
                >
                  Verify Code <ArrowRight className="h-4 w-4" />
                </button>
              </form>
            </>
          )}

          {/* ── Step: New password ──────────────────────────────────── */}
          {step === 'password' && (
            <>
              <div className="mb-6">
                <div className="w-12 h-12 rounded-full bg-brand-50 flex items-center justify-center mb-4">
                  <Lock className="h-6 w-6 text-brand-500" />
                </div>
                <h2 className="font-display text-xl font-bold text-content mb-1">
                  {firstName ? `Hi ${firstName}, set a new password` : 'Set a new password'}
                </h2>
                <p className="text-sm text-content-muted">Choose something strong that you haven't used before.</p>
              </div>

              {serverError && (
                <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-3 py-2.5 text-sm mb-4">
                  <AlertCircle className="h-4 w-4 flex-shrink-0" /> {serverError}
                </div>
              )}

              <form onSubmit={passwordForm.handleSubmit(onPasswordSubmit)} noValidate className="space-y-4">
                <div>
                  <label htmlFor="fp-new-password" className="block text-sm font-medium text-content mb-1.5">New password</label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                    <input
                      id="fp-new-password"
                      type={showNew ? 'text' : 'password'}
                      autoComplete="new-password"
                      placeholder="Create a strong password"
                      {...passwordForm.register('newPassword')}
                      className={`w-full pl-10 pr-10 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                        passwordForm.formState.errors.newPassword ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                      }`}
                    />
                    <button type="button" onClick={() => setShowNew((v) => !v)} className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle hover:text-content-muted">
                      {showNew ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  {newPasswordValue.length > 0 && (
                    <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1">
                      {PASSWORD_RULES.map(({ label, test }) => {
                        const ok = test(newPasswordValue);
                        return (
                          <div key={label} className="flex items-center gap-1.5 text-xs">
                            <CheckCircle2 className={`h-3.5 w-3.5 ${ok ? 'text-emerald-500' : 'text-content-subtle'}`} />
                            <span className={ok ? 'text-emerald-600' : 'text-content-subtle'}>{label}</span>
                          </div>
                        );
                      })}
                    </div>
                  )}
                  {passwordForm.formState.errors.newPassword && (
                    <p className="mt-1.5 text-xs text-red-600 flex items-center gap-1">
                      <AlertCircle className="h-3 w-3" /> {passwordForm.formState.errors.newPassword.message}
                    </p>
                  )}
                </div>

                <div>
                  <label htmlFor="fp-confirm-password" className="block text-sm font-medium text-content mb-1.5">Confirm password</label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                    <input
                      id="fp-confirm-password"
                      type={showConfirm ? 'text' : 'password'}
                      autoComplete="new-password"
                      placeholder="Repeat your password"
                      {...passwordForm.register('confirmPassword')}
                      className={`w-full pl-10 pr-10 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                        passwordForm.formState.errors.confirmPassword ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                      }`}
                    />
                    <button type="button" onClick={() => setShowConfirm((v) => !v)} className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle hover:text-content-muted">
                      {showConfirm ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  {passwordForm.formState.errors.confirmPassword && (
                    <p className="mt-1.5 text-xs text-red-600 flex items-center gap-1">
                      <AlertCircle className="h-3 w-3" /> {passwordForm.formState.errors.confirmPassword.message}
                    </p>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={passwordForm.formState.isSubmitting || !passwordForm.formState.isValid}
                  className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
                >
                  {passwordForm.formState.isSubmitting ? 'Resetting…' : <><span>Reset Password</span><ArrowRight className="h-4 w-4" /></>}
                </button>
              </form>
            </>
          )}

          {/* ── Step: Done ──────────────────────────────────────────── */}
          {step === 'done' && (
            <div className="text-center py-4">
              <div className="w-14 h-14 rounded-full bg-emerald-50 flex items-center justify-center mx-auto mb-4">
                <CheckCircle2 className="h-7 w-7 text-emerald-500" />
              </div>
              <h2 className="font-display text-xl font-bold text-content mb-2">
                {userId ? 'Password reset!' : 'Check your email'}
              </h2>
              <p className="text-sm text-content-muted mb-6">
                {userId
                  ? 'Your password has been updated. You can now sign in with your new password.'
                  : "If an account exists for that email, we've sent a verification code."}
              </p>
              <button
                onClick={onClose}
                className="w-full bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors"
              >
                Back to Sign In
              </button>
            </div>
          )}

        </div>
      </div>
    </div>
  );
};
