import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { Bell, Check, CheckCheck } from 'lucide-react';
import { notificationsApi } from '../../api/notificationsApi';

export const NotificationPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery({
    queryKey: ['notifications', page],
    queryFn: () => notificationsApi.getAll({ pageNo: page, pageSize: 20 }).then((r) => r.data.data),
  });

  const notifications = (data as any)?.items ?? [];
  const totalPages = (data as any)?.totalPages ?? 1;
  const unreadCount = notifications.filter((n: any) => !n.isRead).length;

  const markRead = useMutation({
    mutationFn: (id: number) => notificationsApi.markRead(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      queryClient.invalidateQueries({ queryKey: ['notifications-preview'] });
    },
  });

  const markAll = useMutation({
    mutationFn: () => notificationsApi.markAllRead(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      queryClient.invalidateQueries({ queryKey: ['notifications-preview'] });
    },
  });

  return (
    <div className="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="font-display text-2xl font-bold text-content">Notifications</h1>
          {unreadCount > 0 && (
            <p className="text-sm text-content-muted mt-1">{unreadCount} unread</p>
          )}
        </div>
        {unreadCount > 0 && (
          <button
            onClick={() => markAll.mutate()}
            disabled={markAll.isPending}
            className="flex items-center gap-1.5 text-sm font-semibold text-brand-500 hover:text-brand-600 transition-colors"
          >
            <CheckCheck className="h-4 w-4" />
            Mark all read
          </button>
        )}
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="h-16 bg-surface-sunken rounded-2xl animate-pulse" />
          ))}
        </div>
      ) : notifications.length === 0 ? (
        <div className="text-center py-20 bg-surface-elevated rounded-2xl border border-outline/60">
          <div className="w-16 h-16 bg-surface rounded-full flex items-center justify-center mx-auto mb-4">
            <Bell className="h-7 w-7 text-content-subtle" />
          </div>
          <p className="font-semibold text-content mb-1">No notifications</p>
          <p className="text-sm text-content-subtle">You're all caught up!</p>
        </div>
      ) : (
        <>
          <div className="bg-surface-elevated rounded-2xl border border-outline/60 divide-y divide-outline/60 overflow-hidden">
            <AnimatePresence initial={false}>
              {notifications.map((n: any) => (
                <motion.div
                  key={n.id}
                  layout
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className={`flex items-start gap-3 px-5 py-4 transition-colors ${!n.isRead ? 'bg-brand-50/40' : ''}`}
                >
                  <div className={`w-2.5 h-2.5 rounded-full flex-shrink-0 mt-1.5 ${n.isRead ? 'bg-surface-sunken' : 'bg-brand-500'}`} />
                  <div className="flex-1">
                    <p className={`text-sm ${n.isRead ? 'text-content-muted' : 'font-semibold text-content'}`}>
                      {n.title}
                    </p>
                    <p className="text-xs text-content-muted mt-0.5">{n.message}</p>
                    <p className="text-[10px] text-content-subtle mt-1.5">
                      {new Date(n.createdAt).toLocaleDateString('en-IN', {
                        day: 'numeric', month: 'long', year: 'numeric',
                      })}
                    </p>
                  </div>
                  {!n.isRead && (
                    <button
                      onClick={() => markRead.mutate(n.id)}
                      className="p-1.5 text-content-subtle hover:text-brand-500 transition-colors flex-shrink-0"
                      title="Mark as read"
                    >
                      <Check className="h-4 w-4" />
                    </button>
                  )}
                </motion.div>
              ))}
            </AnimatePresence>
          </div>

          {totalPages > 1 && (
            <div className="flex items-center justify-center gap-3 mt-6">
              <button
                disabled={page <= 1}
                onClick={() => setPage((p) => p - 1)}
                className="px-4 py-2 border border-outline rounded-xl text-sm font-medium text-content hover:bg-surface transition-colors disabled:opacity-40"
              >
                Previous
              </button>
              <span className="text-sm text-content-muted">{page} / {totalPages}</span>
              <button
                disabled={page >= totalPages}
                onClick={() => setPage((p) => p + 1)}
                className="px-4 py-2 border border-outline rounded-xl text-sm font-medium text-content hover:bg-surface transition-colors disabled:opacity-40"
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  );
};
