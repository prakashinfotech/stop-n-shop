import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { X, Mail, Phone, AlertCircle, ArrowRight, Eye, EyeOff } from 'lucide-react';
import { useAuthContext } from '../../context/AuthContext';
import { useLogin } from '../../features/auth/useAuth';
import { useOtpTimer } from '../../hooks/useOtpTimer';
import { OtpInput } from './OtpInput';
import { useToast } from '../ui/Toast';

interface AuthModalProps {
  open: boolean;
  onClose: () => void;
  returnMessage?: string;
}

type Tab  = 'email' | 'otp';
type Step = 'mobile' | 'otp';

export const AuthModal: React.FC<AuthModalProps> = ({
  open,
  onClose,
  returnMessage = 'Sign in to continue',
}) => {
  const [tab, setTab]   = useState<Tab>('email');
  const [step, setStep] = useState<Step>('mobile');

  const [email, setEmail]       = useState('');
  const [password, setPassword] = useState('');
  const [showPwd, setShowPwd]   = useState(false);
  const [emailError, setEmailError] = useState('');

  const [mobile, setMobile]           = useState('');
  const [otp, setOtp]                 = useState('');
  const [mobileError, setMobileError] = useState('');
  const [otpError, setOtpError]       = useState('');
  const [flashOtp, setFlashOtp]       = useState<string | null>(null);
  const flashTimerRef = React.useRef<ReturnType<typeof setTimeout> | null>(null);

  const showFlashOtp = (code: string) => {
    if (flashTimerRef.current) clearTimeout(flashTimerRef.current);
    setFlashOtp(code);
    flashTimerRef.current = setTimeout(() => setFlashOtp(null), 5000);
  };

  const { sendOtp, verifyOtp, isAuthenticated } = useAuthContext();
  const { submit: loginSubmit, isLoading, serverError } = useLogin();
  const { timer, isRunning, start: startTimer } = useOtpTimer(60);
  const { showToast } = useToast();
  const navigate = useNavigate();

  useEffect(() => {
    if (isAuthenticated && open) onClose();
  }, [isAuthenticated, open, onClose]);

  useEffect(() => {
    if (!open) {
      setTab('email'); setStep('mobile');
      setEmail(''); setPassword(''); setEmailError('');
      setMobile(''); setOtp(''); setMobileError(''); setOtpError('');
    }
  }, [open]);

  if (!open) return null;

  const handleEmailLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) { setEmailError('Please fill all fields'); return; }
    setEmailError('');
    try {
      await loginSubmit({ email, password });
      showToast('Welcome back!');
    } catch {
      // serverError handles display
    }
  };

  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!/^\d{10}$/.test(mobile)) { setMobileError('Enter a valid 10-digit number'); return; }
    setMobileError('');
    try {
      const code = await sendOtp(mobile);
      setStep('otp');
      startTimer();
      showToast('OTP sent');
      if (code) showFlashOtp(code);
    } catch {
      setMobileError('Could not send OTP. Please try again.');
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    if (otp.length !== 6) { setOtpError('Enter the 6-digit OTP'); return; }
    setOtpError('');
    try {
      const profile = await verifyOtp(mobile, otp);
      showToast('Welcome to StopNShop!');
      if (profile.role === 'Admin') navigate('/admin/dashboard');
    } catch {
      setOtpError('Invalid or expired OTP.');
    }
  };

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}
    >
      <div className="bg-surface-elevated rounded-2xl shadow-2xl w-full max-w-sm relative overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-outline/60">
          <div>
            <h2 className="font-display text-lg font-bold text-content">Sign In</h2>
            <p className="text-xs text-content-muted mt-0.5">{returnMessage}</p>
          </div>
          <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-surface-sunken text-content-muted transition-colors">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="p-5">
          {/* Tabs */}
          <div className="flex bg-surface-sunken rounded-xl p-1 mb-5">
            <button
              type="button"
              onClick={() => setTab('email')}
              className={`flex-1 flex items-center justify-center gap-1.5 py-1.5 text-xs font-medium rounded-lg transition-all ${
                tab === 'email' ? 'bg-surface-elevated text-content shadow-sm' : 'text-content-muted hover:text-content'
              }`}
            >
              <Mail className="h-3.5 w-3.5" /> Email
            </button>
            <button
              type="button"
              onClick={() => { setTab('otp'); setStep('mobile'); setOtp(''); setOtpError(''); }}
              className={`flex-1 flex items-center justify-center gap-1.5 py-1.5 text-xs font-medium rounded-lg transition-all ${
                tab === 'otp' ? 'bg-surface-elevated text-content shadow-sm' : 'text-content-muted hover:text-content'
              }`}
            >
              <Phone className="h-3.5 w-3.5" /> Mobile OTP
            </button>
          </div>

          {/* Email form */}
          {tab === 'email' && (
            <form onSubmit={handleEmailLogin} noValidate className="space-y-3">
              {(serverError || emailError) && (
                <div className="flex items-center gap-2 bg-red-50 text-red-700 border border-red-200 rounded-xl px-3 py-2 text-xs">
                  <AlertCircle className="h-3.5 w-3.5 flex-shrink-0" />
                  {serverError || emailError}
                </div>
              )}
              <input
                type="email"
                placeholder="Email address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
                className="w-full px-4 py-2.5 border border-outline rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400"
              />
              <div className="relative">
                <input
                  type={showPwd ? 'text' : 'password'}
                  placeholder="Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  className="w-full px-4 pr-10 py-2.5 border border-outline rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-300 focus:border-brand-400"
                />
                <button
                  type="button"
                  onClick={() => setShowPwd((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-content-subtle hover:text-content-muted"
                >
                  {showPwd ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              <button
                type="submit"
                disabled={isLoading}
                className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-2.5 rounded-xl text-sm transition-colors disabled:opacity-60"
              >
                {isLoading ? 'Signing in…' : <><span>Sign In</span> <ArrowRight className="h-4 w-4" /></>}
              </button>
            </form>
          )}

          {/* OTP flow */}
          {tab === 'otp' && step === 'mobile' && (
            <form onSubmit={handleSendOtp} noValidate className="space-y-3">
              <div className="flex">
                <span className="inline-flex items-center px-3 border border-r-0 border-outline rounded-l-xl bg-surface text-sm text-content-muted font-medium">
                  +91
                </span>
                <input
                  type="tel"
                  placeholder="10-digit mobile"
                  value={mobile}
                  onChange={(e) => { setMobile(e.target.value.replace(/\D/g, '').slice(0, 10)); setMobileError(''); }}
                  maxLength={10}
                  className={`flex-1 px-4 py-2.5 border rounded-r-xl text-sm focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                    mobileError ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                  }`}
                />
              </div>
              {mobileError && (
                <p className="text-xs text-red-600 flex items-center gap-1">
                  <AlertCircle className="h-3 w-3" /> {mobileError}
                </p>
              )}
              <button
                type="submit"
                className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-2.5 rounded-xl text-sm transition-colors"
              >
                Send OTP <ArrowRight className="h-4 w-4" />
              </button>
            </form>
          )}

          {tab === 'otp' && step === 'otp' && (
            <form onSubmit={handleVerifyOtp} noValidate className="space-y-4">
              <p className="text-xs text-center text-content-muted">
                OTP sent to <span className="font-semibold">+91 {mobile}</span>
              </p>

              {/* Dev OTP flash — visible for 5 seconds */}
              {flashOtp && (
                <div className="flex items-center justify-center gap-2 bg-amber-50 border border-amber-300 rounded-xl px-3 py-2.5 animate-pulse">
                  <span className="text-xs text-amber-700 font-medium">Your OTP:</span>
                  <span className="text-xl font-black tracking-[0.25em] text-amber-900">{flashOtp}</span>
                </div>
              )}

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
                  <button
                    type="button"
                    onClick={async () => {
                      try {
                        const code = await sendOtp(mobile);
                        startTimer(); setOtp(''); setOtpError('');
                        if (code) showFlashOtp(code);
                      } catch { showToast('Could not resend OTP', 'error'); }
                    }}
                    className="text-brand-500 hover:underline font-medium"
                  >
                    Resend OTP
                  </button>
                )}
              </div>
              <button
                type="submit"
                className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-2.5 rounded-xl text-sm transition-colors"
              >
                Verify & Sign In <ArrowRight className="h-4 w-4" />
              </button>
              <button
                type="button"
                onClick={() => { setStep('mobile'); setOtp(''); setOtpError(''); }}
                className="w-full text-xs text-content-muted hover:text-content text-center"
              >
                ← Change number
              </button>
            </form>
          )}

          <div className="mt-4 pt-4 border-t border-outline/60 flex items-center justify-between text-xs text-content-muted">
            <Link to="/user/signup" onClick={onClose} className="text-brand-500 font-medium hover:underline">
              Create account
            </Link>
            <button onClick={() => { onClose(); navigate('/home'); }} className="hover:text-content">
              Browse without signing in →
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
