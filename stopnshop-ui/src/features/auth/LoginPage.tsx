import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  Phone, Mail, Lock, Eye, EyeOff, AlertCircle, ArrowRight, ArrowLeft,
} from 'lucide-react';
import { useAuthContext } from '../../context/AuthContext';
import { useLogin } from './useAuth';
import { useOtpTimer } from '../../hooks/useOtpTimer';
import { OtpInput } from '../../components/auth/OtpInput';
import { useToast } from '../../components/ui/Toast';
import { ForgotPasswordModal } from '../../components/auth/ForgotPasswordModal';

const BRAND_IMAGE = 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=900&q=80';

// ── Email login schema ──────────────────────────────────────────────
const emailSchema = z.object({
  email:      z.string().email('Enter a valid email address'),
  password:   z.string().min(1, 'Password is required'),
  rememberMe: z.boolean().optional(),
});
type EmailFormValues = z.infer<typeof emailSchema>;

type Tab = 'email' | 'otp';

export const LoginPage: React.FC = () => {
  const [tab, setTab]     = useState<Tab>('email');
  const [step, setStep]   = useState<'mobile' | 'otp'>('mobile');
  const [mobile, setMobile]             = useState('');
  const [otp, setOtp]                   = useState('');
  const [mobileError, setMobileError]   = useState('');
  const [otpError, setOtpError]         = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [flashOtp, setFlashOtp]         = useState<string | null>(null);
  const [forgotOpen, setForgotOpen]     = useState(false);
  const flashTimerRef = React.useRef<ReturnType<typeof setTimeout> | null>(null);

  const { sendOtp, verifyOtp, isAuthenticated, user } = useAuthContext();
  const { submit: loginSubmit, isLoading: emailLoading, serverError, clearError } = useLogin();
  const { timer, isRunning, start: startTimer } = useOtpTimer(60);
  const { showToast } = useToast();
  const navigate  = useNavigate();
  const location  = useLocation();
  const returnUrl = (location.state as { returnUrl?: string })?.returnUrl;

  useEffect(() => {
    if (!isAuthenticated) return;
    const isAdmin = user?.role === 'Admin';
    navigate(returnUrl ?? (isAdmin ? '/admin/dashboard' : '/home'), { replace: true });
  }, [isAuthenticated, navigate, returnUrl, user]);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<EmailFormValues>({ resolver: zodResolver(emailSchema), mode: 'onChange' });

  // ── OTP flash helper ─────────────────────────────────────────────
  const showFlashOtp = (code: string) => {
    if (flashTimerRef.current) clearTimeout(flashTimerRef.current);
    setFlashOtp(code);
    flashTimerRef.current = setTimeout(() => setFlashOtp(null), 5000);
  };

  // ── OTP handlers ─────────────────────────────────────────────────
  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!/^\d{10}$/.test(mobile)) {
      setMobileError('Enter a valid 10-digit mobile number');
      return;
    }
    setMobileError('');
    try {
      const code = await sendOtp(mobile);
      setStep('otp');
      startTimer();
      showToast('OTP sent to your mobile number');
      if (code) showFlashOtp(code);
    } catch {
      setMobileError('Could not send OTP. Please try again.');
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (otp.length !== 6) {
      setOtpError('Enter the 6-digit OTP');
      return;
    }
    setOtpError('');
    try {
      await verifyOtp(mobile, otp);
      showToast('Welcome to StopNShop!');
    } catch {
      setOtpError('Invalid or expired OTP. Please try again.');
    }
  };

  const handleResend = async () => {
    if (isRunning) return;
    try {
      const code = await sendOtp(mobile);
      startTimer();
      setOtp('');
      setOtpError('');
      showToast('OTP resent successfully');
      if (code) showFlashOtp(code);
    } catch {
      showToast('Could not resend OTP', 'error');
    }
  };

  // ── Email login handler ──────────────────────────────────────────
  const onEmailSubmit = async (data: EmailFormValues) => {
    try {
      await loginSubmit(data);
      showToast('Welcome back!');
    } catch {
      // error shown via serverError
    }
  };

  return (
    <div className="min-h-screen flex">
      {/* ── Left brand panel ──────────────────────────────────────── */}
      <div className="hidden lg:flex lg:w-[45%] relative overflow-hidden">
        <img src={BRAND_IMAGE} alt="StopNShop fashion" className="absolute inset-0 w-full h-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-br from-stone-900/85 via-brand-900/70 to-transparent" />
        <div className="relative z-10 flex flex-col justify-between p-12 text-white h-full">
          <Link to="/">
            <span className="font-display text-3xl font-bold tracking-tight">
              Stop<span className="text-brand-300">N</span>Shop
            </span>
          </Link>
          <div>
            <div className="inline-flex items-center gap-2 bg-surface-elevated/10 backdrop-blur-sm rounded-full px-4 py-1.5 text-xs text-white/80 mb-6">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block animate-pulse" />
              Trusted by 2 million+ shoppers
            </div>
            <h2 className="font-display text-4xl font-bold leading-tight mb-4">
              Your style,<br />your story.
            </h2>
            <p className="text-white/70 text-base leading-relaxed max-w-sm">
              Sign in to access exclusive deals, track your orders, and enjoy a personalised shopping experience.
            </p>
            <div className="flex flex-wrap items-center gap-3 mt-8">
              {['Free Shipping', 'Easy Returns', 'Exclusive Offers', 'Loyalty Points'].map((perk) => (
                <div key={perk} className="flex items-center gap-1.5 text-sm text-white/75 bg-surface-elevated/10 rounded-full px-3 py-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-brand-300 inline-block" />
                  {perk}
                </div>
              ))}
            </div>
          </div>
          <p className="text-white/30 text-xs">© {new Date().getFullYear()} StopNShop. All rights reserved.</p>
        </div>
      </div>

      {/* ── Right form panel ──────────────────────────────────────── */}
      <div className="w-full lg:w-[55%] flex items-center justify-center px-6 py-12 bg-surface">
        <div className="w-full max-w-md">
          {/* Mobile logo */}
          <Link to="/" className="flex lg:hidden justify-center mb-8">
            <span className="font-display text-2xl font-bold text-brand-500">
              Stop<span className="text-content">N</span>Shop
            </span>
          </Link>

          {/* Card */}
          <div className="bg-surface-elevated rounded-2xl shadow-sm border border-outline/60 p-8">
            <div className="mb-6">
              <h1 className="font-display text-2xl font-bold text-content mb-1">Welcome back</h1>
              <p className="text-content-muted text-sm">
                New here?{' '}
                <Link to="/user/signup" className="text-brand-500 font-semibold hover:underline">
                  Create an account
                </Link>
              </p>
            </div>

            {/* Tab switcher */}
            <div className="flex bg-surface-sunken rounded-xl p-1 mb-6">
              <button
                type="button"
                onClick={() => setTab('email')}
                className={`flex-1 flex items-center justify-center gap-2 py-2 text-sm font-medium rounded-lg transition-all ${
                  tab === 'email'
                    ? 'bg-surface-elevated text-content shadow-sm'
                    : 'text-content-muted hover:text-content'
                }`}
              >
                <Mail className="h-4 w-4" /> Email
              </button>
              <button
                type="button"
                onClick={() => { setTab('otp'); setStep('mobile'); setOtp(''); setOtpError(''); }}
                className={`flex-1 flex items-center justify-center gap-2 py-2 text-sm font-medium rounded-lg transition-all ${
                  tab === 'otp'
                    ? 'bg-surface-elevated text-content shadow-sm'
                    : 'text-content-muted hover:text-content'
                }`}
              >
                <Phone className="h-4 w-4" /> Mobile OTP
              </button>
            </div>

            {/* ── Email tab ─────────────────────────────────────── */}
            {tab === 'email' && (
              <form onSubmit={handleSubmit(onEmailSubmit)} noValidate className="space-y-4">
                {serverError && (
                  <div className="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 rounded-xl px-3 py-2.5 text-sm">
                    <AlertCircle className="h-4 w-4 flex-shrink-0" />
                    {serverError}
                  </div>
                )}

                <div>
                  <label htmlFor="email" className="block text-sm font-medium text-content mb-1.5">
                    Email address
                  </label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                    <input
                      id="email"
                      type="email"
                      autoComplete="email"
                      placeholder="you@example.com"
                      {...register('email', { onChange: () => clearError() })}
                      className={`w-full pl-10 pr-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                        errors.email ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                      }`}
                    />
                  </div>
                  <p className={`mt-1.5 text-xs flex items-center gap-1 overflow-hidden transition-all ${
                    errors.email ? 'text-red-600 h-auto' : 'h-0'
                  }`}>
                    {errors.email && <><AlertCircle className="h-3 w-3" /> {errors.email.message}</>}
                  </p>
                </div>

                <div>
                  <div className="flex items-center justify-between mb-1.5">
                    <label htmlFor="password" className="block text-sm font-medium text-content">
                      Password
                    </label>
                    <button type="button" className="text-xs text-brand-500 hover:underline" onClick={() => setForgotOpen(true)}>
                      Forgot password?
                    </button>
                  </div>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                    <input
                      id="password"
                      type={showPassword ? 'text' : 'password'}
                      autoComplete="current-password"
                      placeholder="Your password"
                      {...register('password', { onChange: () => clearError() })}
                      className={`w-full pl-10 pr-10 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                        errors.password ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                      }`}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword((v) => !v)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle hover:text-content-muted"
                      aria-label={showPassword ? 'Hide' : 'Show'}
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  <p className={`mt-1.5 text-xs flex items-center gap-1 overflow-hidden transition-all ${
                    errors.password ? 'text-red-600 h-auto' : 'h-0'
                  }`}>
                    {errors.password && <><AlertCircle className="h-3 w-3" /> {errors.password.message}</>}
                  </p>
                </div>

                <label className="flex items-center gap-2 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    {...register('rememberMe')}
                    className="w-4 h-4 rounded border-outline-strong text-brand-500 focus:ring-brand-300"
                  />
                  <span className="text-sm text-content-muted">Remember me for 30 days</span>
                </label>

                <button
                  type="submit"
                  disabled={emailLoading}
                  className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60"
                >
                  {emailLoading ? 'Signing in…' : <><span>Sign In</span> <ArrowRight className="h-4 w-4" /></>}
                </button>
              </form>
            )}

            {/* ── OTP tab ───────────────────────────────────────── */}
            {tab === 'otp' && (
              <>
                {step === 'mobile' && (
                  <form onSubmit={handleSendOtp} noValidate className="space-y-4">
                    <div>
                      <label htmlFor="mobile" className="block text-sm font-medium text-content mb-1.5">
                        Mobile Number
                      </label>
                      <div className="flex">
                        <span className="inline-flex items-center px-3 border border-r-0 border-outline rounded-l-xl bg-surface text-sm text-content-muted font-medium">
                          +91
                        </span>
                        <input
                          id="mobile"
                          type="tel"
                          value={mobile}
                          onChange={(e) => { setMobile(e.target.value.replace(/\D/g, '').slice(0, 10)); setMobileError(''); }}
                          placeholder="10-digit number"
                          maxLength={10}
                          className={`flex-1 px-4 py-3 border rounded-r-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                            mobileError ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                          }`}
                        />
                      </div>
                      <p className={`mt-1.5 text-xs flex items-center gap-1 overflow-hidden transition-all ${
                        mobileError ? 'text-red-600 h-auto' : 'h-0'
                      }`}>
                        {mobileError && <><AlertCircle className="h-3 w-3" /> {mobileError}</>}
                      </p>
                    </div>

                    <button
                      type="submit"
                      className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors"
                    >
                      Send OTP <ArrowRight className="h-4 w-4" />
                    </button>
                  </form>
                )}

                {step === 'otp' && (
                  <form onSubmit={handleVerifyOtp} noValidate className="space-y-5">
                    <button
                      type="button"
                      onClick={() => { setStep('mobile'); setOtp(''); setOtpError(''); }}
                      className="flex items-center gap-1.5 text-sm text-content-muted hover:text-content -mt-1"
                    >
                      <ArrowLeft className="h-4 w-4" /> Change number
                    </button>

                    <div className="text-center">
                      <p className="text-sm text-content-muted">
                        OTP sent to <span className="font-semibold text-content">+91 {mobile}</span>
                      </p>
                    </div>

                    {/* Dev OTP flash — visible for 5 seconds after send/resend */}
                    {flashOtp && (
                      <div className="flex items-center justify-center gap-3 bg-amber-50 border border-amber-300 rounded-xl px-4 py-3 animate-pulse">
                        <span className="text-xs text-amber-700 font-medium">Your OTP:</span>
                        <span className="text-2xl font-black tracking-[0.3em] text-amber-900">{flashOtp}</span>
                      </div>
                    )}

                    <OtpInput value={otp} onChange={setOtp} hasError={!!otpError} />

                    <p className={`text-xs flex items-center justify-center gap-1 overflow-hidden transition-all ${
                      otpError ? 'text-red-600 h-auto' : 'h-0'
                    }`}>
                      {otpError && <><AlertCircle className="h-3 w-3" /> {otpError}</>}
                    </p>

                    <div className="text-center text-sm">
                      {isRunning ? (
                        <span className="text-content-subtle">Resend OTP in <span className="font-semibold text-content-muted">{timer}s</span></span>
                      ) : (
                        <button type="button" onClick={handleResend} className="text-brand-500 font-medium hover:underline">
                          Resend OTP
                        </button>
                      )}
                    </div>

                    <button
                      type="submit"
                      className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors"
                    >
                      Verify & Sign In <ArrowRight className="h-4 w-4" />
                    </button>
                  </form>
                )}
              </>
            )}

            {/* Continue browsing CTA */}
            <div className="mt-5 pt-5 border-t border-outline/60 text-center">
              <Link
                to={returnUrl === '/user/login' || !returnUrl ? '/home' : returnUrl}
                className="text-sm text-content-muted hover:text-content hover:underline transition-colors"
              >
                Continue browsing without signing in →
              </Link>
            </div>
          </div>

          <p className="text-center text-xs text-content-subtle mt-4">
            By signing in you agree to our{' '}
            <Link to="/terms" className="underline hover:text-content-muted">Terms</Link>
            {' & '}
            <Link to="/privacy" className="underline hover:text-content-muted">Privacy Policy</Link>.
          </p>
        </div>
      </div>

      {forgotOpen && <ForgotPasswordModal onClose={() => setForgotOpen(false)} />}
    </div>
  );
};
