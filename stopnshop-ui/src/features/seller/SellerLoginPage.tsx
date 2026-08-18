import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Mail, Lock, Eye, EyeOff, AlertCircle, ArrowRight } from 'lucide-react';
import { useSellerAuth } from './useSellerAuth';

const BRAND_IMAGE = 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=900&q=80';

const loginSchema = z.object({
  email: z.string().email('Enter a valid email address'),
  password: z.string().min(1, 'Password is required'),
});

type LoginFormValues = z.infer<typeof loginSchema>;

export const SellerLoginPage: React.FC = () => {
  const navigate = useNavigate();
  const { login } = useSellerAuth();

  const [showPassword, setShowPassword] = useState(false);
  const [apiError, setApiError] = useState('');

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormValues>({ resolver: zodResolver(loginSchema) });

  const onSubmit = async (data: LoginFormValues) => {
    setApiError('');
    try {
      await login(data.email, data.password);
      navigate('/seller/dashboard', { replace: true });
    } catch (error: any) {
      setApiError(error.message || 'Login failed. Please try again.');
    }
  };

  const inputClass = (hasError: boolean) =>
    `w-full px-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
      hasError ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
    }`;

  return (
    <div className="min-h-screen flex">
      {/* ── Left brand panel ──────────────────────────────────────── */}
      <div className="hidden lg:flex lg:w-[45%] relative overflow-hidden">
        <img src={BRAND_IMAGE} alt="StopNShop seller" className="absolute inset-0 w-full h-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-br from-stone-900/85 via-brand-900/60 to-transparent" />
        <div className="relative z-10 flex flex-col justify-between p-12 text-white h-full">
          <Link to="/">
            <span className="font-display text-3xl font-bold tracking-tight">
              Stop<span className="text-brand-300">N</span>Shop
            </span>
          </Link>
          <div>
            <div className="inline-flex items-center gap-2 bg-surface-elevated/10 backdrop-blur-sm rounded-full px-4 py-1.5 text-xs text-white/80 mb-6">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block animate-pulse" />
              Join 50,000+ sellers
            </div>
            <h2 className="font-display text-4xl font-bold leading-tight mb-4">
              Sell smarter,<br />grow faster.
            </h2>
            <p className="text-white/70 text-base leading-relaxed max-w-sm">
              Access your dashboard, manage inventory, track orders, and scale your business with StopNShop.
            </p>
            <div className="grid grid-cols-2 gap-3 mt-8">
              {[
                { stat: '50,000+', label: 'Active Sellers' },
                { stat: '2M+', label: 'Customers' },
                { stat: '24/7', label: 'Support' },
                { stat: '2.5%', label: 'Commission' },
              ].map(({ stat, label }) => (
                <div key={label} className="bg-surface-elevated/10 backdrop-blur-sm rounded-xl px-4 py-3">
                  <p className="text-xl font-bold text-white">{stat}</p>
                  <p className="text-xs text-white/60 mt-0.5">{label}</p>
                </div>
              ))}
            </div>
          </div>
          <p className="text-white/30 text-xs">© {new Date().getFullYear()} StopNShop Seller Network</p>
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
                Don't have an account?{' '}
                <Link to="/seller/register" className="text-brand-500 font-semibold hover:underline">
                  Create one
                </Link>
              </p>
            </div>

            {/* Error */}
            {apiError && (
              <div className="flex items-start gap-3 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 mb-5 text-sm">
                <AlertCircle className="h-4 w-4 mt-0.5 flex-shrink-0" />
                <span>{apiError}</span>
              </div>
            )}

            <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-3">
              {/* Email */}
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
                    placeholder="your@business.com"
                    {...register('email')}
                    className={`${inputClass(!!errors.email)} pl-10`}
                  />
                </div>
                {errors.email ? (
                  <p className="mt-1 text-xs text-red-600 flex items-center gap-1">
                    <AlertCircle className="h-3 w-3" /> {errors.email.message}
                  </p>
                ) : null}
              </div>

              {/* Password */}
              <div>
                <label htmlFor="password" className="block text-sm font-medium text-content mb-1.5">
                  Password
                </label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="current-password"
                    placeholder="Your password"
                    {...register('password')}
                    className={`${inputClass(!!errors.password)} pl-10 pr-10`}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle hover:text-content-muted"
                  >
                    {showPassword ? <Eye className="h-4 w-4" /> : <EyeOff className="h-4 w-4" />}
                  </button>
                </div>
                {errors.password ? (
                  <p className="mt-1 text-xs text-red-600 flex items-center gap-1">
                    <AlertCircle className="h-3 w-3" /> {errors.password.message}
                  </p>
                ) : null}
              </div>

              {/* Remember me & Forgot password */}
              <div className="flex items-center justify-between">
                <label className="flex items-center gap-2 cursor-pointer select-none">
                  <input type="checkbox" className="w-4 h-4 rounded border-outline-strong text-brand-500" />
                  <span className="text-sm text-content-muted">Remember me</span>
                </label>
                <button type="button" className="text-xs text-brand-500 hover:underline">
                  Forgot password?
                </button>
              </div>

              {/* Submit */}
              <button
                type="submit"
                disabled={isSubmitting}
                className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60"
              >
                {isSubmitting ? 'Signing in…' : <><span>Sign In</span> <ArrowRight className="h-4 w-4" /></>}
              </button>
            </form>

            {/* Signup link */}
            <div className="mt-4 pt-4 border-t border-outline/60 text-center">
              <p className="text-sm text-content-muted">
                New to StopNShop?{' '}
                <Link to="/seller/register" className="text-brand-500 font-semibold hover:underline">
                  Get started selling →
                </Link>
              </p>
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
    </div>
  );
};
