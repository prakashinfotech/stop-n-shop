import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  Eye, EyeOff, Mail, Lock, User, Phone, AlertCircle, CheckCircle2, ArrowRight,
} from 'lucide-react';
import { useRegister } from './useAuth';
import { useAuthContext } from '../../context/AuthContext';

const BRAND_IMAGE = 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=900&q=80';

const signupSchema = z
  .object({
    firstName:       z.string().min(2, 'At least 2 characters').max(50, 'Too long'),
    lastName:        z.string().min(2, 'At least 2 characters').max(50, 'Too long'),
    email:           z.string().email('Enter a valid email address'),
    mobile:          z.string().regex(/^\d{10}$/, 'Enter a valid 10-digit mobile number'),
    password:        z
      .string()
      .min(8, 'At least 8 characters')
      .regex(/[A-Z]/, 'Add an uppercase letter')
      .regex(/[0-9]/, 'Add a number'),
    confirmPassword: z.string().min(1, 'Please confirm your password'),
    gender:          z.string().optional(),
    terms:           z.boolean().refine((v) => v === true, { message: 'You must accept the terms to create an account' }),
  })
  .refine((d) => d.password === d.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });

type SignupFormValues = z.infer<typeof signupSchema>;

const PASSWORD_RULES = [
  { label: 'At least 8 characters', test: (v: string) => v.length >= 8 },
  { label: 'One uppercase letter',  test: (v: string) => /[A-Z]/.test(v) },
  { label: 'One number',            test: (v: string) => /[0-9]/.test(v) },
];

export const SignupPage: React.FC = () => {
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirm,  setShowConfirm]  = useState(false);
  const { submit, isLoading, serverError } = useRegister();
  const { isAuthenticated } = useAuthContext();
  const navigate = useNavigate();

  useEffect(() => {
    if (isAuthenticated) navigate('/', { replace: true });
  }, [isAuthenticated, navigate]);

  const {
    register,
    handleSubmit,
    watch,
    formState: { errors, isValid },
  } = useForm<SignupFormValues>({
    resolver: zodResolver(signupSchema),
    mode: 'onChange'
  });

  const passwordValue = watch('password', '');

  const onSubmit = async (data: SignupFormValues) => {
    try {
      await submit({
        firstName:   data.firstName,
        lastName:    data.lastName,
        email:       data.email,
        mobile:      data.mobile,
        password:    data.password,
        gender:      data.gender || undefined,
        countryCode: '+91',
      });
      // Set welcome flag — HomePage reads and removes it
      localStorage.setItem('sns_welcome_new', data.firstName);
      // Navigate after successful signup
      navigate('/', { replace: true });
    } catch {
      // shown via serverError
    }
  };

  return (
    <div className="min-h-screen flex">
      {/* Left brand panel */}
      <div className="hidden lg:flex lg:w-[45%] relative overflow-hidden">
        <img src={BRAND_IMAGE} alt="StopNShop fashion" className="absolute inset-0 w-full h-full object-cover" />
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
              Join 2 million+ happy shoppers
            </div>
            <h2 className="font-display text-4xl font-bold leading-tight mb-4">
              Join the StopNShop<br />community today.
            </h2>
            <p className="text-white/70 text-base leading-relaxed max-w-sm">
              Unlock exclusive offers, early access to new arrivals, and a personalised shopping experience.
            </p>
            <div className="grid grid-cols-2 gap-3 mt-8">
              {[
                { stat: '10,000+', label: 'Styles' },
                { stat: '500+',    label: 'Brands' },
                { stat: '50+',     label: 'Stores' },
                { stat: '4.8★',    label: 'Avg Rating' },
              ].map(({ stat, label }) => (
                <div key={label} className="bg-surface-elevated/10 backdrop-blur-sm rounded-xl px-4 py-3">
                  <p className="text-xl font-bold text-white">{stat}</p>
                  <p className="text-xs text-white/60 mt-0.5">{label}</p>
                </div>
              ))}
            </div>
          </div>
          <p className="text-white/30 text-xs">© {new Date().getFullYear()} StopNShop. All rights reserved.</p>
        </div>
      </div>

      {/* Right form panel */}
      <div className="w-full lg:w-[55%] flex items-center justify-center px-6 py-12 bg-surface overflow-y-auto">
        <div className="w-full max-w-md">

          <Link to="/" className="flex lg:hidden justify-center mb-8">
            <span className="font-display text-2xl font-bold text-brand-500">
              Stop<span className="text-content">N</span>Shop
            </span>
          </Link>

          <div className="bg-surface-elevated rounded-2xl shadow-sm border border-outline/60 p-8">
            <div className="mb-6">
              <h1 className="font-display text-2xl font-bold text-content mb-1">Create account</h1>
              <p className="text-content-muted text-sm">
                Already have an account?{' '}
                <Link to="/user/login" className="text-brand-500 font-semibold hover:underline">Sign in</Link>
              </p>
            </div>

            {serverError && (
              <div className="flex items-start gap-3 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 mb-5 text-sm">
                <AlertCircle className="h-4 w-4 mt-0.5 flex-shrink-0" />
                <span>{serverError}</span>
              </div>
            )}

            <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-4">
              {/* Name row */}
              <div className="grid grid-cols-2 gap-3">
                <FieldWrapper label="First name" error={errors.firstName?.message}>
                  <div className="relative">
                    <User className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                    <input
                      id="firstName"
                      type="text"
                      placeholder="Jane"
                      {...register('firstName')}
                      className={inputClass(!!errors.firstName, true)}
                    />
                  </div>
                </FieldWrapper>
                <FieldWrapper label="Last name" error={errors.lastName?.message}>
                  <input
                    id="lastName"
                    type="text"
                    placeholder="Doe"
                    {...register('lastName')}
                    className={inputClass(!!errors.lastName, false)}
                  />
                </FieldWrapper>
              </div>

              {/* Email */}
              <FieldWrapper label="Email address" error={errors.email?.message}>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                  <input
                    id="email"
                    type="email"
                    autoComplete="email"
                    placeholder="you@example.com"
                    {...register('email')}
                    className={inputClass(!!errors.email, true)}
                  />
                </div>
              </FieldWrapper>

              {/* Mobile */}
              <FieldWrapper label="Mobile number" error={errors.mobile?.message}>
                <div className="flex">
                  <span className="inline-flex items-center px-3 border border-r-0 border-outline rounded-l-xl bg-surface text-sm text-content-muted font-medium whitespace-nowrap">
                    <Phone className="h-4 w-4 mr-1.5 text-content-subtle" /> +91
                  </span>
                  <input
                    id="mobile"
                    type="tel"
                    placeholder="10-digit number"
                    maxLength={10}
                    {...register('mobile')}
                    className={`flex-1 px-4 py-3 border rounded-r-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                      errors.mobile ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                    }`}
                  />
                </div>
              </FieldWrapper>

              {/* Gender (optional) */}
              <FieldWrapper label="Gender (optional)">
                <select
                  {...register('gender')}
                  className="w-full px-4 py-3 border border-outline rounded-xl text-sm text-content bg-surface-elevated focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400 transition appearance-none"
                >
                  <option value="">Prefer not to say</option>
                  <option value="Male">Male</option>
                  <option value="Female">Female</option>
                  <option value="Other">Other</option>
                </select>
              </FieldWrapper>

              {/* Password */}
              <FieldWrapper label="Password" error={errors.password?.message}>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    autoComplete="new-password"
                    placeholder="Create a strong password"
                    {...register('password')}
                    className={inputClass(!!errors.password, true, true)}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle hover:text-content-muted"
                  >
                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
                {passwordValue.length > 0 && (
                  <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1">
                    {PASSWORD_RULES.map(({ label, test }) => {
                      const ok = test(passwordValue);
                      return (
                        <div key={label} className="flex items-center gap-1.5 text-xs">
                          <CheckCircle2 className={`h-3.5 w-3.5 ${ok ? 'text-emerald-500' : 'text-content-subtle'}`} />
                          <span className={ok ? 'text-emerald-600' : 'text-content-subtle'}>{label}</span>
                        </div>
                      );
                    })}
                  </div>
                )}
              </FieldWrapper>

              {/* Confirm password */}
              <FieldWrapper label="Confirm password" error={errors.confirmPassword?.message}>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                  <input
                    id="confirmPassword"
                    type={showConfirm ? 'text' : 'password'}
                    autoComplete="new-password"
                    placeholder="Repeat your password"
                    {...register('confirmPassword')}
                    className={inputClass(!!errors.confirmPassword, true, true)}
                  />
                  <button
                    type="button"
                    onClick={() => setShowConfirm((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle hover:text-content-muted"
                  >
                    {showConfirm ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
                {passwordValue.length > 0 && watch('confirmPassword', '').length > 0 && (
                  <div className="mt-2">
                    {passwordValue === watch('confirmPassword') ? (
                      <div className="flex items-center gap-1.5 text-xs text-emerald-600">
                        <CheckCircle2 className="h-3.5 w-3.5 text-emerald-500" />
                        Passwords match
                      </div>
                    ) : (
                      <div className="flex items-center gap-1.5 text-xs text-red-600">
                        <AlertCircle className="h-3.5 w-3.5 text-red-500" />
                        Passwords do not match
                      </div>
                    )}
                  </div>
                )}
              </FieldWrapper>

              {/* Terms */}
              <div>
                <label className="flex items-start gap-2.5 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    {...register('terms')}
                    className="w-4 h-4 mt-0.5 rounded border-outline-strong text-brand-500 focus:ring-brand-300"
                  />
                  <span className="text-xs text-content-muted leading-relaxed">
                    I agree to the{' '}
                    <Link to="/terms" className="text-brand-500 hover:underline">Terms of Service</Link>
                    {' '}and{' '}
                    <Link to="/privacy" className="text-brand-500 hover:underline">Privacy Policy</Link>
                  </span>
                </label>
                <p className={`mt-1 text-xs flex items-center gap-1 overflow-hidden transition-all ${
                  errors.terms ? 'text-red-600 h-auto' : 'h-0'
                }`}>
                  {errors.terms && <><AlertCircle className="h-3 w-3" /> {errors.terms.message}</>}
                </p>
              </div>

              <button
                type="submit"
                disabled={isLoading || !isValid}
                className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
              >
                {isLoading ? 'Creating account…' : <><span>Create Account</span> <ArrowRight className="h-4 w-4" /></>}
              </button>
            </form>

            <div className="mt-4 pt-4 border-t border-outline/60 text-center">
              <Link to="/" className="text-sm text-content-muted hover:text-content hover:underline">
                Continue browsing without an account →
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

/* ── Helpers ─────────────────────────────────────────────────────── */

const inputClass = (hasError: boolean, hasIcon: boolean, hasRightIcon = false) =>
  `w-full ${hasIcon ? 'pl-10' : 'pl-4'} ${hasRightIcon ? 'pr-10' : 'pr-4'} py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
    hasError ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
  }`;

interface FieldWrapperProps {
  label: string;
  error?: string;
  children: React.ReactNode;
}

const FieldWrapper: React.FC<FieldWrapperProps> = ({ label, error, children }) => (
  <div>
    <label className="block text-sm font-medium text-content mb-1.5">{label}</label>
    {children}
    <p className={`mt-1.5 text-xs flex items-center gap-1 overflow-hidden transition-all ${
      error ? 'text-red-600 h-auto' : 'h-0'
    }`}>
      {error && <><AlertCircle className="h-3 w-3" /> {error}</>}
    </p>
  </div>
);
