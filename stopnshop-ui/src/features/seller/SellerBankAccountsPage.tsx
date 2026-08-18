import React, { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { CheckCircle2, Star, Plus } from 'lucide-react';
import { SellerLayout } from '../../components/layout/SellerLayout';
import { Spinner } from '../../components/ui/Spinner';
import { sellerLifecycleApi, type AddBankAccountRequest } from '../../api/sellerLifecycleApi';

export const SellerBankAccountsPage: React.FC = () => {
  const qc = useQueryClient();
  const [showForm, setShowForm] = useState(false);

  const { data: accounts, isLoading } = useQuery({
    queryKey: ['seller-bank-accounts'],
    queryFn: () => sellerLifecycleApi.bankAccounts.list().then(r => r.data.data),
    staleTime: 60_000,
  });

  const addMutation = useMutation({
    mutationFn: (req: AddBankAccountRequest) => sellerLifecycleApi.bankAccounts.add(req),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['seller-bank-accounts'] });
      setShowForm(false);
    },
  });

  const setPrimaryMutation = useMutation({
    mutationFn: (id: number) => sellerLifecycleApi.bankAccounts.setPrimary(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['seller-bank-accounts'] }),
  });

  const isFirstAccount = !accounts || accounts.length === 0;

  const { register, handleSubmit, reset, formState: { errors } } = useForm<AddBankAccountRequest>();

  const onSubmit = (data: AddBankAccountRequest) => {
    addMutation.mutate(data, { onSuccess: () => reset() });
  };

  return (
    <SellerLayout>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-display font-bold text-content mb-2">Bank Accounts</h1>
          <p className="text-content-muted">Settlements are paid to your primary bank account.</p>
        </div>
        <button onClick={() => setShowForm(s => !s)}
                className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 text-white rounded-lg hover:bg-brand-700 font-medium">
          <Plus size={16} /> Add bank account
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit(onSubmit)}
              className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-6 mb-6 grid grid-cols-1 md:grid-cols-2 gap-4">
          <input {...register('accountHolderName', { required: true })}
                 placeholder="Account holder name" className="px-3 py-2 border rounded-md" />
          <input {...register('bankName', { required: true })}
                 placeholder="Bank name" className="px-3 py-2 border rounded-md" />
          <input {...register('accountNumber', { required: true })}
                 placeholder="Account number" className="px-3 py-2 border rounded-md" />
          <input {...register('ifscCode', { required: true })}
                 placeholder="IFSC code" className="px-3 py-2 border rounded-md" />
          <input {...register('branchName')} placeholder="Branch name (optional)"
                 className="px-3 py-2 border rounded-md" />
          {/* First account is mandatorily primary — settlement payouts need
              an unambiguous destination. Once a primary exists, additional
              accounts default to non-primary; SP enforces the rule too. */}
          <label className="flex items-center gap-2 text-sm">
            <input
              type="checkbox"
              defaultChecked={isFirstAccount}
              disabled={isFirstAccount}
              {...register('isPrimary')}
            />
            Set as primary
            {isFirstAccount && (
              <span className="text-xs text-content-subtle">(required — first account)</span>
            )}
          </label>
          <div className="md:col-span-2 flex justify-end gap-3">
            {Object.keys(errors).length > 0 && (
              <span className="text-sm text-rose-700 self-center">All fields are required.</span>
            )}
            <button type="button" onClick={() => setShowForm(false)}
                    className="px-4 py-2 border border-outline rounded-lg hover:bg-surface">Cancel</button>
            <button type="submit" disabled={addMutation.isPending}
                    className="px-4 py-2 bg-brand-600 text-white rounded-lg disabled:opacity-50">
              {addMutation.isPending ? 'Saving…' : 'Save account'}
            </button>
          </div>
        </form>
      )}

      {isLoading ? (
        <div className="flex justify-center py-16"><Spinner /></div>
      ) : !accounts || accounts.length === 0 ? (
        <div className="bg-surface-elevated rounded-2xl shadow-soft border border-outline/60 p-16 text-center text-content-muted">
          No bank accounts on file yet.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {accounts.map(a => (
            <div key={a.bankAccountId}
                 className={`bg-surface-elevated rounded-2xl shadow-soft border p-6 ${a.isPrimary ? 'border-brand-500 ring-1 ring-brand-200' : 'border-outline/60'}`}>
              <div className="flex items-start justify-between">
                <div>
                  <p className="font-semibold text-content">{a.bankName}</p>
                  <p className="text-sm text-content-muted mt-1">{a.accountHolderName}</p>
                  <p className="text-sm font-mono text-content-muted mt-2">•••• {a.accountNumber.slice(-4)}</p>
                  <p className="text-xs text-content-subtle mt-1">IFSC {a.ifscCode}</p>
                </div>
                <div className="flex flex-col items-end gap-2">
                  {a.isPrimary && (
                    <span className="inline-flex items-center gap-1 px-2 py-1 bg-brand-50 text-brand-700 rounded-full text-xs font-medium">
                      <Star size={12} /> Primary
                    </span>
                  )}
                  {a.isVerified && (
                    <span className="inline-flex items-center gap-1 px-2 py-1 bg-emerald-50 text-emerald-700 rounded-full text-xs font-medium">
                      <CheckCircle2 size={12} /> Verified
                    </span>
                  )}
                </div>
              </div>
              {!a.isPrimary && (
                <button onClick={() => setPrimaryMutation.mutate(a.bankAccountId)}
                        disabled={setPrimaryMutation.isPending}
                        className="mt-4 text-sm text-brand-600 hover:text-brand-700 font-medium">
                  Set as primary
                </button>
              )}
            </div>
          ))}
        </div>
      )}
    </SellerLayout>
  );
};
