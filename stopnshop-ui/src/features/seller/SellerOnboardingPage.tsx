import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ChevronRight, ChevronLeft, AlertCircle, CheckCircle2, ArrowRight } from 'lucide-react';
import { useSellerAuth } from './useSellerAuth';
import { sellerApi } from '../../api/sellerApi';
import { useToast } from '../../components/ui/Toast';

type OnboardingStep = 'verification' | 'categories' | 'store' | 'address';

interface OnboardingForm {
  ownerFullName: string;
  displayName: string;
  storeDescription: string;
  isPhoneVerified: boolean;
  isEmailVerified: boolean;
  isIdVerified: boolean;
  allCategories: boolean;
  selectedCategoryIds: number[];
  pickupAddressLine1: string;
  pickupAddressLine2: string;
  pickupCity: string;
  pickupState: string;
  pickupPincode: string;
  pickupLandmark: string;
}

interface Category {
  id: number;
  name: string;
}

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

export const SellerOnboardingPage: React.FC = () => {
  const navigate = useNavigate();
  const { completeOnboarding, logout } = useSellerAuth();

  const handleSignout = () => {
    logout();
    navigate('/seller/login');
  };
  const { showToast } = useToast();

  const [step, setStep] = useState<OnboardingStep>('verification');
  const [formData, setFormData] = useState<OnboardingForm>({
    ownerFullName: '',
    displayName: '',
    storeDescription: '',
    isPhoneVerified: true,
    isEmailVerified: true,
    isIdVerified: false,
    allCategories: true,
    selectedCategoryIds: [],
    pickupAddressLine1: '',
    pickupAddressLine2: '',
    pickupCity: '',
    pickupState: '',
    pickupPincode: '',
    pickupLandmark: '',
  });

  const [categories, setCategories] = useState<Category[]>([]);
  const [categoriesLoading, setCategoriesLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(false);
  const [apiError, setApiError] = useState('');
  const [isSuccess, setIsSuccess] = useState(false);

  useEffect(() => {
    if (step === 'categories' && categories.length === 0) {
      loadCategories();
    }
  }, [step]);

  const loadCategories = async () => {
    setCategoriesLoading(true);
    try {
      const response = await sellerApi.catalogue.getCategories();
      if (response.data?.success) {
        setCategories(response.data.data || []);
      }
    } catch {
      showToast('Failed to load categories', 'error');
    } finally {
      setCategoriesLoading(false);
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors((prev) => ({ ...prev, [name]: '' }));
    }
  };

  const validateStep = (currentStep: OnboardingStep): boolean => {
    const newErrors: Record<string, string> = {};

    switch (currentStep) {
      case 'verification':
        if (!formData.isIdVerified) {
          newErrors.isIdVerified = 'Please confirm your identity';
        }
        break;

      case 'categories':
        if (!formData.allCategories && formData.selectedCategoryIds.length === 0) {
          newErrors.selectedCategories = 'Please select at least one category';
        }
        break;

      case 'store':
        if (!formData.ownerFullName.trim()) {
          newErrors.ownerFullName = 'Owner name is required';
        }
        if (!formData.displayName.trim()) {
          newErrors.displayName = 'Display name is required';
        }
        if (!formData.storeDescription.trim()) {
          newErrors.storeDescription = 'Store description is required';
        }
        break;

      case 'address':
        if (!formData.pickupAddressLine1.trim()) {
          newErrors.pickupAddressLine1 = 'Address is required';
        }
        if (!formData.pickupCity.trim()) {
          newErrors.pickupCity = 'City is required';
        }
        if (!formData.pickupState.trim()) {
          newErrors.pickupState = 'State is required';
        }
        if (!formData.pickupPincode.trim()) {
          newErrors.pickupPincode = 'Pincode is required';
        } else if (!/^\d{6}$/.test(formData.pickupPincode)) {
          newErrors.pickupPincode = 'Pincode must be 6 digits';
        }
        break;
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleNextStep = () => {
    if (!validateStep(step)) return;

    const steps: OnboardingStep[] = ['verification', 'categories', 'store', 'address'];
    const currentIndex = steps.indexOf(step);
    if (currentIndex < steps.length - 1) {
      setStep(steps[currentIndex + 1]);
    }
  };

  const handlePrevStep = () => {
    const steps: OnboardingStep[] = ['verification', 'categories', 'store', 'address'];
    const currentIndex = steps.indexOf(step);
    if (currentIndex > 0) {
      setStep(steps[currentIndex - 1]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateStep(step)) return;

    setIsLoading(true);
    setApiError('');

    try {
      await completeOnboarding({
        ownerFullName: formData.ownerFullName,
        displayName: formData.displayName,
        storeDescription: formData.storeDescription,
        isPhoneVerified: formData.isPhoneVerified,
        isEmailVerified: formData.isEmailVerified,
        isIdVerified: formData.isIdVerified,
        allCategories: formData.allCategories,
        selectedCategoryIds: formData.selectedCategoryIds,
        pickupAddressLine1: formData.pickupAddressLine1,
        pickupAddressLine2: formData.pickupAddressLine2,
        pickupCity: formData.pickupCity,
        pickupState: formData.pickupState,
        pickupPincode: formData.pickupPincode,
        pickupLandmark: formData.pickupLandmark,
      });

      setIsSuccess(true);
      showToast('Onboarding completed! Welcome to StopNShop');
    } catch (error: any) {
      setApiError(error.message || 'Failed to complete onboarding');
    } finally {
      setIsLoading(false);
    }
  };

  const steps: OnboardingStep[] = ['verification', 'categories', 'store', 'address'];
  const currentStepIndex = steps.indexOf(step);
  const totalSteps = steps.length;

  if (isSuccess) {
    return (
      <div className="min-h-screen flex items-center justify-center px-6 py-12 bg-surface">
        <div className="w-full max-w-md">
          <div className="bg-surface-elevated rounded-2xl shadow-sm border border-outline/60 p-8 text-center">
            <div className="mb-6 flex justify-center">
              <div className="w-16 h-16 rounded-full bg-emerald-50 flex items-center justify-center">
                <CheckCircle2 className="w-8 h-8 text-emerald-600" />
              </div>
            </div>

            <h1 className="font-display text-2xl font-bold text-content mb-2">Onboarding Complete!</h1>
            <p className="text-content-muted mb-8">You're all set to start selling on StopNShop. Let's get your products listed.</p>

            <div className="space-y-3">
              <button
                onClick={() => navigate('/seller/products/new')}
                className="w-full flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl text-sm transition-colors"
              >
                <span>Add Products</span> <ArrowRight className="h-4 w-4" />
              </button>
              <button
                onClick={() => navigate('/seller/dashboard')}
                className="w-full flex items-center justify-center gap-2 bg-brand-500 hover:bg-brand-600 text-white font-semibold py-3 rounded-xl text-sm transition-colors"
              >
                <span>Go to Dashboard</span> <ArrowRight className="h-4 w-4" />
              </button>
              <button
                onClick={() => navigate('/seller/products')}
                className="w-full text-brand-500 font-medium py-3 rounded-xl hover:bg-surface transition-colors"
              >
                View Product Listing →
              </button>
              <button
                onClick={handleSignout}
                className="w-full text-content-muted font-medium py-2 text-sm hover:text-content transition-colors"
              >
                Sign out
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center px-6 py-12 bg-surface">
      <div className="w-full max-w-md">
        <div className="bg-surface-elevated rounded-2xl shadow-sm border border-outline/60 p-8">
          <div className="mb-6 flex items-start justify-between gap-4">
            <div>
              <h1 className="font-display text-2xl font-bold text-content mb-1">Complete Your Setup</h1>
              <p className="text-content-muted text-sm">Just a few more details to go live</p>
            </div>
            <button
              type="button"
              onClick={handleSignout}
              className="text-xs font-medium text-content-muted hover:text-brand-500 transition-colors whitespace-nowrap mt-1"
            >
              Sign out
            </button>
          </div>

          {/* Step Indicator */}
          <div className="mb-6 space-y-2">
            <div className="flex items-center justify-between text-xs text-content-muted">
              <span>Step {currentStepIndex + 1} of {totalSteps}</span>
              <span className="font-semibold">
                {step === 'verification' && 'Verification'}
                {step === 'categories' && 'Categories'}
                {step === 'store' && 'Store Details'}
                {step === 'address' && 'Pickup Address'}
              </span>
            </div>
            <div className="w-full bg-surface-sunken rounded-full h-1 overflow-hidden">
              <div
                className="bg-gradient-to-r from-brand-500 to-brand-600 h-full transition-all duration-300"
                style={{ width: `${((currentStepIndex + 1) / totalSteps) * 100}%` }}
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

          <form onSubmit={handleSubmit} noValidate className="space-y-3">
            {/* Step 1: Verification Status */}
            {step === 'verification' && (
              <>
                <div className="space-y-3 mb-6">
                  <div className="flex items-center gap-3 p-3 bg-emerald-50 rounded-lg border border-emerald-200">
                    <CheckCircle2 className="h-5 w-5 text-emerald-600 flex-shrink-0" />
                    <span className="text-sm text-content"><strong>Phone Verified</strong> — +91 {formData.ownerFullName === '' ? '****' : ''}</span>
                  </div>
                  <div className="flex items-center gap-3 p-3 bg-emerald-50 rounded-lg border border-emerald-200">
                    <CheckCircle2 className="h-5 w-5 text-emerald-600 flex-shrink-0" />
                    <span className="text-sm text-content"><strong>Email Verified</strong> — {formData.displayName === '' ? '****' : ''}</span>
                  </div>
                </div>

                <FieldWrapper label="ID & Signature Verification" error={errors.isIdVerified}>
                  <label className="flex items-start gap-2.5 cursor-pointer select-none p-3 border border-outline rounded-xl hover:bg-surface transition">
                    <input
                      type="checkbox"
                      checked={formData.isIdVerified}
                      onChange={(e) => setFormData((prev) => ({ ...prev, isIdVerified: e.target.checked }))}
                      className="w-4 h-4 mt-0.5 rounded border-outline-strong text-brand-500 focus:ring-brand-300"
                    />
                    <span className="text-xs text-content leading-relaxed">
                      I confirm that the information I provide is accurate and complete. I understand that providing false information may result in account suspension.
                    </span>
                  </label>
                </FieldWrapper>
              </>
            )}

            {/* Step 2: Categories */}
            {step === 'categories' && (
              <>
                <div className="space-y-3">
                  <label className="flex items-center gap-3 cursor-pointer p-3 border-2 rounded-xl transition" style={{ borderColor: formData.allCategories ? '#3b82f6' : '#e5e7eb', backgroundColor: formData.allCategories ? '#eff6ff' : '' }}>
                    <input
                      type="radio"
                      checked={formData.allCategories}
                      onChange={() => setFormData((prev) => ({ ...prev, allCategories: true }))}
                      className="w-4 h-4"
                    />
                    <div>
                      <p className="text-sm font-medium text-content">All Categories</p>
                      <p className="text-xs text-content-muted">Sell across all available categories</p>
                    </div>
                  </label>

                  <label className="flex items-center gap-3 cursor-pointer p-3 border-2 rounded-xl transition" style={{ borderColor: !formData.allCategories ? '#3b82f6' : '#e5e7eb', backgroundColor: !formData.allCategories ? '#eff6ff' : '' }}>
                    <input
                      type="radio"
                      checked={!formData.allCategories}
                      onChange={() => setFormData((prev) => ({ ...prev, allCategories: false }))}
                      className="w-4 h-4"
                    />
                    <div>
                      <p className="text-sm font-medium text-content">Select Categories</p>
                      <p className="text-xs text-content-muted">Choose specific categories to sell</p>
                    </div>
                  </label>
                </div>

                {!formData.allCategories && (
                  <div className="mt-6">
                    <label className="block text-sm font-medium text-content mb-3">Select Categories</label>
                    {categoriesLoading ? (
                      <p className="text-sm text-content-muted">Loading categories...</p>
                    ) : (
                      <div className="space-y-2 max-h-60 overflow-y-auto">
                        {categories.map((cat) => (
                          <label key={cat.id} className="flex items-center gap-2 cursor-pointer p-2 rounded hover:bg-surface">
                            <input
                              type="checkbox"
                              checked={formData.selectedCategoryIds.includes(cat.id)}
                              onChange={(e) => {
                                if (e.target.checked) {
                                  setFormData((prev) => ({ ...prev, selectedCategoryIds: [...prev.selectedCategoryIds, cat.id] }));
                                } else {
                                  setFormData((prev) => ({ ...prev, selectedCategoryIds: prev.selectedCategoryIds.filter((id) => id !== cat.id) }));
                                }
                              }}
                              className="w-4 h-4 rounded border-outline-strong text-brand-500"
                            />
                            <span className="text-sm text-content">{cat.name}</span>
                          </label>
                        ))}
                      </div>
                    )}
                    {errors.selectedCategories && (
                      <p className="mt-1 text-xs text-red-600 flex items-center gap-1">
                        <AlertCircle className="h-3 w-3" /> {errors.selectedCategories}
                      </p>
                    )}
                  </div>
                )}
              </>
            )}

            {/* Step 3: Store Details */}
            {step === 'store' && (
              <>
                <FieldWrapper label="Owner Full Name *" error={errors.ownerFullName}>
                  <input
                    type="text"
                    placeholder="Your name"
                    name="ownerFullName"
                    value={formData.ownerFullName}
                    onChange={handleInputChange}
                    className={`w-full px-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                      errors.ownerFullName ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                    }`}
                  />
                </FieldWrapper>

                <FieldWrapper label="Store Display Name *" error={errors.displayName}>
                  <input
                    type="text"
                    placeholder="Your store name (visible to customers)"
                    name="displayName"
                    value={formData.displayName}
                    onChange={handleInputChange}
                    className={`w-full px-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                      errors.displayName ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                    }`}
                  />
                </FieldWrapper>

                <FieldWrapper label="Store Description *" error={errors.storeDescription}>
                  <textarea
                    placeholder="Tell customers about your store..."
                    name="storeDescription"
                    value={formData.storeDescription}
                    onChange={handleInputChange}
                    rows={4}
                    className={`w-full px-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 resize-none ${
                      errors.storeDescription ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                    }`}
                  />
                </FieldWrapper>
              </>
            )}

            {/* Step 4: Pickup Address */}
            {step === 'address' && (
              <>
                <FieldWrapper label="Pickup Address Line 1 *" error={errors.pickupAddressLine1}>
                  <input
                    type="text"
                    placeholder="Street address"
                    name="pickupAddressLine1"
                    value={formData.pickupAddressLine1}
                    onChange={handleInputChange}
                    className={`w-full px-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                      errors.pickupAddressLine1 ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                    }`}
                  />
                </FieldWrapper>

                <FieldWrapper label="Pickup Address Line 2 (Optional)">
                  <input
                    type="text"
                    placeholder="Apartment, suite, etc."
                    name="pickupAddressLine2"
                    value={formData.pickupAddressLine2}
                    onChange={handleInputChange}
                    className="w-full px-4 py-3 border border-outline rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 bg-surface-elevated"
                  />
                </FieldWrapper>

                <div className="grid grid-cols-2 gap-3">
                  <FieldWrapper label="City *" error={errors.pickupCity}>
                    <input
                      type="text"
                      placeholder="City"
                      name="pickupCity"
                      value={formData.pickupCity}
                      onChange={handleInputChange}
                      className={`w-full px-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                        errors.pickupCity ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                      }`}
                    />
                  </FieldWrapper>

                  <FieldWrapper label="State *" error={errors.pickupState}>
                    <input
                      type="text"
                      placeholder="State"
                      name="pickupState"
                      value={formData.pickupState}
                      onChange={handleInputChange}
                      className={`w-full px-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                        errors.pickupState ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                      }`}
                    />
                  </FieldWrapper>
                </div>

                <FieldWrapper label="Pincode *" error={errors.pickupPincode}>
                  <input
                    type="text"
                    placeholder="6-digit pincode"
                    maxLength={6}
                    name="pickupPincode"
                    value={formData.pickupPincode}
                    onChange={handleInputChange}
                    className={`w-full px-4 py-3 border rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 ${
                      errors.pickupPincode ? 'border-red-400 bg-red-50' : 'border-outline bg-surface-elevated focus:border-brand-400'
                    }`}
                  />
                </FieldWrapper>

                <FieldWrapper label="Landmark (Optional)">
                  <input
                    type="text"
                    placeholder="Near..."
                    name="pickupLandmark"
                    value={formData.pickupLandmark}
                    onChange={handleInputChange}
                    className="w-full px-4 py-3 border border-outline rounded-xl text-sm transition focus:outline-none focus:ring-2 focus:ring-brand-300 bg-surface-elevated"
                  />
                </FieldWrapper>
              </>
            )}

            {/* Navigation Buttons */}
            <div className="flex gap-3 pt-4">
              <button
                type="button"
                onClick={handlePrevStep}
                disabled={currentStepIndex === 0 || isLoading}
                className="flex-1 flex items-center justify-center gap-2 bg-surface-elevated border-2 border-outline text-content font-semibold py-3 rounded-xl hover:bg-surface transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
              >
                <ChevronLeft size={18} />
                Back
              </button>

              {currentStepIndex < totalSteps - 1 ? (
                <button
                  type="button"
                  onClick={handleNextStep}
                  disabled={isLoading}
                  className="flex-1 flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl transition-colors disabled:opacity-60"
                >
                  Next
                  <ChevronRight size={18} />
                </button>
              ) : (
                <button
                  type="submit"
                  disabled={isLoading}
                  className="flex-1 flex items-center justify-center gap-2 bg-stone-900 hover:bg-brand-500 text-white font-semibold py-3 rounded-xl transition-colors disabled:opacity-60"
                >
                  {isLoading ? 'Saving…' : <><span>Save & Continue</span> <ArrowRight className="h-4 w-4" /></>}
                </button>
              )}
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};
