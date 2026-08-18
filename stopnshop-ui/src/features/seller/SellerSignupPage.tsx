import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Mail, Lock, Eye, EyeOff, Phone, AlertCircle, ArrowRight, ArrowLeft, CheckCircle2 } from 'lucide-react';
import { useSellerAuth } from './useSellerAuth';
import { useOtpTimer } from '../../hooks/useOtpTimer';
import { OtpInput } from '../../components/auth/OtpInput';
import { useToast } from '../../components/ui/Toast';

const BRAND_IMAGE = 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=900&q=80';

type SignupStep = 'credentials' | 'phone-otp' | 'email-otp';

interface SignupForm {
  email: string;
  phoneNumber: string;
  password: string;
  confirmPassword: string;
}

const PASSWORD_RULES = [
  { label: 'At least 8 characters', test: (v: string) => v.length >= 8 },
  { label: 'One uppercase letter', test: (v: string) => /[A-Z]/.test(v) },
  { label: 'One number', test: (v: string) => /[0-9]/.test(v) },
];

const FieldWrapper: React.FC<{ label: string; error?: string; children: React.ReactNode }> = ({ label, error, children }) => (
  <div>
    <label className="block text-sm font-medium text-content mb-1.5">{label}</label>
    {children}
    {error ? (
      <p className="mt-1 text-xs text-red-600 flex items-center gap-1">
        <AlertCircle className="h-3 w-3" /> {error}
      </p>
    ) : null}
  </div>
);

export const SellerSignupPage: React.FC = () => {
  const navigate = useNavigate();
  const { signup } = useSellerAuth();
  const { showToast } = useToast();
  const { timer, isRunning, start: startTimer } = useOtpTimer(60);

  const [step, setStep] = useState<SignupStep>('credentials');
  const [formData, setFormData] = useState<SignupForm>({
    email: '',
    phoneNumber: '',
    password: '',
    confirmPassword: '',
  });

  const [phoneOtp, setPhoneOtp] = useState('');
  const [emailOtp, setEmailOtp] = useState('');
  const [phoneOtpError, setPhoneOtpError] = useState('');
  const [emailOtpError, setEmailOtpError] = useState('');
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(false);
  const [apiError, setApiError] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [generatedPhoneOtp, setGeneratedPhoneOtp] = useState('');
  const [generatedEmailOtp, setGeneratedEmailOtp] = useState('');

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: '' }));
    }
    setApiError('');
  };

  const validateCredentials = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Invalid email address';
    }

    if (!formData.phoneNumber.trim()) {
      newErrors.phoneNumber = 'Phone number is required';
    } else if (!/^\d{10}$/.test(formData.phoneNumber.replace(/\D/g, ''))) {
      newErrors.phoneNumber = 'Phone number must be 10 digits';
    }

    if (!formData.password) {
      newErrors.password = 'Password is required';
    } else if (formData.password.length < 8) {
      newErrors.password = 'Password must be at least 8 characters';
    } else if (!/[A-Z]/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one uppercase letter';
    } else if (!/[0-9]/.test(formData.password)) {
      newErrors.password = 'Password must contain at least one digit';
    }

    if (!formData.confirmPassword) {
      newErrors.confirmPassword = 'Confirm password is required';
    } else if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSignupSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateCredentials()) return;

    setIsLoading(true);
    setApiError('');

    try {
      const result = await signup({
        email: formData.email.trim(),
        phoneNumber: formData.phoneNumber.replace(/\D/g, ''),
        password: formData.password,
        confirmPassword: formData.confirmPassword,
      });

      setGeneratedPhoneOtp(result.phoneOtp);
      setGeneratedEmailOtp(result.emailOtp);
      setStep('phone-otp');
      startTimer();
      showToast('OTPs generated. Check the form for testing.');
    } catch (error: any) {
      setApiError(error.message || 'Signup failed. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handlePhoneOtpVerify = (e: React.FormEvent) => {
    e.preventDefault();
    if (phoneOtp.length !== 6) {
      setPhoneOtpError('Enter the 6-digit OTP');
      return;
    }

    // Client-side OTP verification
    if (phoneOtp !== generatedPhoneOtp) {
      setPhoneOtpError('Invalid OTP. Please try again.');
      return;
    }

    setPhoneOtpError('');
    setStep('email-otp');
    setPhoneOtp('');
    startTimer();
    showToast('Phone verified! Now verify email.');
  };

  const handleEmailOtpVerify = (e: React.FormEvent) => {
    e.preventDefault();
    if (emailOtp.length !== 6) {
      setEmailOtpError('Enter the 6-digit OTP');
      return;
    }

    // Client-side OTP verification
    if (emailOtp !== generatedEmailOtp) {
      setEmailOtpError('Invalid OTP. Please try again.');
      return;
    }

    setEmailOtpError('');
    showToast('Email verified! Redirecting to onboarding...');
    navigate('/seller/onboarding', { replace: true });
  };

  const handleBackToCredentials = () => {
    setStep('credentials');
    setPhoneOtp('');
    setEmailOtp('');
    setPhoneOtpError('');
    setEmailOtpError('');
  };

  const inputClass = (hasError: boolean, hasIcon: boolean, hasRightIcon = false) =>
    `w-full ${hasIcon ? 'pl-10' : 'pl-4'} ${hasRightIcon ? 'pr-10' : 'pr-4'} py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
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
              Start selling<br />on StopNShop.
            </h2>
            <p className="text-white/70 text-base leading-relaxed max-w-sm">
              Reach millions of customers, manage your inventory, and grow your business with our platform.
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
      <div className="w-full lg:w-[55%] flex items-center justify-center px-6 py-12 bg-surface overflow-y-auto">
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
              <h1 className="font-display text-2xl font-bold text-content mb-1">Create seller account</h1>
              <p className="text-content-muted text-sm">
                Already have an account?{' '}
                <Link to="/seller/login" className="text-brand-500 font-semibold hover:underline">
                  Sign in
                </Link>
              </p>
            </div>

            {/* Step indicator */}
            <div className="mb-6 space-y-2">
              <div className="flex items-center justify-between text-xs text-content-muted">
                <span>
                  {step === 'credentials' && 'Step 1 of 3'}
                  {step === 'phone-otp' && 'Step 2 of 3'}
                  {step === 'email-otp' && 'Step 3 of 3'}
                </span>
                <span className="font-semibold">
                  {step === 'credentials' && 'Credentials'}
                  {step === 'phone-otp' && 'Phone Verification'}
                  {step === 'email-otp' && 'Email Verification'}
                </span>
              </div>
              <div className="w-full bg-surface-sunken rounded-full h-1 overflow-hidden">
                <div
                  className="bg-gradient-to-r from-brand-500 to-brand-600 h-full transition-all duration-300"
                  style={{
                    width: step === 'credentials' ? '33%' : step === 'phone-otp' ? '66%' : '100%',
                  }}
                />
              </div>
            </div>

            {/* API Error */}
            {apiError && (
              <div className="flex items-start gap-3 bg-red-50 border border-red-200 text-red-700 rounded-xl px-4 py-3 mb-5 text-sm">
                <AlertCircle className="h-4 w-4 mt-0.5 flex-shrink-0" />
                <span>{apiError}</span>
              </div>
            )}

            {/* Step 1: Credentials */}
            {step === 'credentials' && (
              <form onSubmit={handleSignupSubmit} noValidate className="space-y-3">
                <FieldWrapper label="Email Address *" error={errors.email}>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                    <input
                      type="email"
                      placeholder="your@business.com"
                      name="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      autoComplete="email"
                      className={inputClass(!!errors.email, true)}
                    />
                  </div>
                </FieldWrapper>

                <FieldWrapper label="Mobile Number *" error={errors.phoneNumber}>
                  <div className="flex">
                    <span className="inline-flex items-center px-3 border border-r-0 border-outline rounded-l-xl bg-surface text-sm text-content-muted font-medium">
                      <Phone className="h-4 w-4 mr-1.5 text-content-subtle" /> +91
                    </span>
                    <input
                      type="tel"
                      placeholder="10-digit number"
                      maxLength={10}
                      name="phoneNumber"
                      value={formData.phoneNumber}
                      onChange={(e) => {
                        const val = e.target.value.replace(/\D/g, '').slice(0, 10);
                        setFormData((prev) => ({ ...prev, phoneNumber: val }));
                        if (errors.phoneNumber) {
                          setErrors((prev) => ({ ...prev, phoneNumber: '' }));
                        }
                      }}
                      className={`flex-1 px-4 py-3 border rounded-r-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                        errors.phoneNumber ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                      }`}
                    />
                  </div>
                </FieldWrapper>

                <FieldWrapper label="Password *" error={errors.password}>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                    <input
                      type={showPassword ? 'text' : 'password'}
                      placeholder="Create a strong password"
                      name="password"
                      value={formData.password}
                      onChange={handleInputChange}
                      autoComplete="new-password"
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
                  {formData.password.length > 0 && (
                    <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1">
                      {PASSWORD_RULES.map(({ label, test }) => {
                        const ok = test(formData.password);
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

                <FieldWrapper label="Confirm Password *" error={errors.confirmPassword}>
                  <div className="relative">
                    <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-content-subtle" />
                    <input
                      type={showConfirmPassword ? 'text' : 'password'}
                      placeholder="Repeat your password"
                      name="confirmPassword"
                      value={formData.confirmPassword}
                      onChange={handleInputChange}
                      autoComplete="new-password"
                      className={inputClass(!!errors.confirmPassword, true, true)}
                    />
                    <button
                      type="button"
                      onClick={() => setShowConfirmPassword((v) => !v)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle hover:text-content-muted"
                    >
                      {showConfirmPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  {formData.password.length > 0 && formData.confirmPassword.length > 0 && (
                    <div className="mt-2">
                      {formData.password === formData.confirmPassword ? (
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

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60"
                >
                  {isLoading ? 'Creating account…' : <><span>Generate OTPs</span> <ArrowRight className="h-4 w-4" /></>}
                </button>
              </form>
            )}

            {/* Step 2: Phone OTP */}
            {step === 'phone-otp' && (
              <form onSubmit={handlePhoneOtpVerify} noValidate className="space-y-5">
                <button
                  type="button"
                  onClick={handleBackToCredentials}
                  className="flex items-center gap-1.5 text-sm text-content-muted hover:text-content -mt-1"
                >
                  <ArrowLeft className="h-4 w-4" /> Change number
                </button>

                <div className="text-center">
                  <p className="text-sm text-content-muted">
                    OTP sent to <span className="font-semibold text-content">+91 {formData.phoneNumber}</span>
                  </p>
                </div>

                {generatedPhoneOtp && (
                  <div className="bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 text-amber-700 text-sm">
                    <p className="font-semibold mb-1">For testing only:</p>
                    <p className="font-mono text-lg tracking-wider">{generatedPhoneOtp}</p>
                  </div>
                )}

                <div>
                  <label className="block text-sm font-medium text-content mb-3">Enter OTP</label>
                  <OtpInput value={phoneOtp} onChange={setPhoneOtp} hasError={!!phoneOtpError} />
                </div>

                {phoneOtpError && (
                  <p className="text-xs text-red-600 flex items-center justify-center gap-1">
                    <AlertCircle className="h-3 w-3" /> {phoneOtpError}
                  </p>
                )}

                <button
                  type="submit"
                  disabled={isLoading || phoneOtp.length !== 6}
                  className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60"
                >
                  {isLoading ? 'Verifying…' : <><span>Verify Phone</span> <ArrowRight className="h-4 w-4" /></>}
                </button>
              </form>
            )}

            {/* Step 3: Email OTP */}
            {step === 'email-otp' && (
              <form onSubmit={handleEmailOtpVerify} noValidate className="space-y-5">
                <div className="text-center">
                  <p className="text-sm text-content-muted">
                    OTP sent to <span className="font-semibold text-content">{formData.email}</span>
                  </p>
                </div>

                {generatedEmailOtp && (
                  <div className="bg-amber-50 border border-amber-200 rounded-xl px-4 py-3 text-amber-700 text-sm">
                    <p className="font-semibold mb-1">For testing only:</p>
                    <p className="font-mono text-lg tracking-wider">{generatedEmailOtp}</p>
                  </div>
                )}

                <div>
                  <label className="block text-sm font-medium text-content mb-3">Enter OTP</label>
                  <OtpInput value={emailOtp} onChange={setEmailOtp} hasError={!!emailOtpError} />
                </div>

                {emailOtpError && (
                  <p className="text-xs text-red-600 flex items-center justify-center gap-1">
                    <AlertCircle className="h-3 w-3" /> {emailOtpError}
                  </p>
                )}

                <div className="text-center text-sm">
                  {isRunning ? (
                    <span className="text-content-subtle">Resend OTP in <span className="font-semibold text-content-muted">{timer}s</span></span>
                  ) : (
                    <button type="button" onClick={() => setPhoneOtp('')} className="text-brand-500 font-medium hover:underline">
                      Resend OTP
                    </button>
                  )}
                </div>

                <button
                  type="submit"
                  disabled={isLoading || emailOtp.length !== 6}
                  className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors disabled:opacity-60"
                >
                  {isLoading ? 'Verifying…' : <><span>Verify & Continue</span> <ArrowRight className="h-4 w-4" /></>}
                </button>
              </form>
            )}

            {/* Footer link */}
            <div className="mt-4 pt-4 border-t border-outline/60 text-center">
              <Link to="/seller/login" className="text-sm text-content-muted hover:text-content hover:underline transition-colors">
                Already have an account? Sign in →
              </Link>
            </div>
          </div>

          <p className="text-center text-xs text-content-subtle mt-4">
            By creating an account you agree to our{' '}
            <Link to="/terms" className="underline hover:text-content-muted">Terms</Link>
            {' & '}
            <Link to="/privacy" className="underline hover:text-content-muted">Privacy Policy</Link>.
          </p>
        </div>
      </div>
    </div>
  );
};
