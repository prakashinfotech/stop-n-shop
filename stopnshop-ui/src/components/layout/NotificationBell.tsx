import React, { useState, useRef, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { motion, AnimatePresence } from 'framer-motion';
import { Bell, Check } from 'lucide-react';
import { notificationsApi } from '../../api/notificationsApi';
import { useAuthContext } from '../../context/AuthContext';

export const NotificationBell: React.FC = () => {
  const { isAuthenticated } = useAuthContext();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const queryClient = useQueryClient();

  const { data } = useQuery({
    queryKey: ['notifications-preview'],
    queryFn: () => notificationsApi.getAll({ pageNo: 1, pageSize: 5 }).then((r) => r.data.data),
    enabled: isAuthenticated,
    refetchInterval: 60_000,
  });

  const notifications = (data as any)?.items ?? [];
  const unreadCount = notifications.filter((n: any) => !n.isRead).length;

  const markReadMutation = useMutation({
    mutationFn: (id: number) => notificationsApi.markRead(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications-preview'] }),
  });

  const markAllMutation = useMutation({
    mutationFn: () => notificationsApi.markAllRead(),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications-preview'] }),
  });

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  if (!isAuthenticated) return null;

  return (
    <div ref={ref} className="relative">
      <button
        onClick={() => setOpen((v) => !v)}
        className="relative p-2 rounded-lg text-content-muted hover:text-brand-500 hover:bg-brand-50 transition-colors"
        aria-label="Notifications"
      >
        <Bell className="h-5 w-5" />
        <AnimatePresence mode="popLayout">
          {unreadCount > 0 && (
            <motion.span
              key={unreadCount}
              initial={{ scale: 0.4, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.4, opacity: 0 }}
              className="absolute -top-0.5 -right-0.5 bg-red-500 text-white text-[10px] font-black rounded-full w-5 h-5 flex items-center justify-center shadow-sm"
            >
              {unreadCount > 9 ? '9+' : unreadCount}
            </motion.span>
          )}
        </AnimatePresence>
      </button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: 8, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 8, scale: 0.97 }}
            transition={{ duration: 0.15 }}
            className="absolute right-0 top-full mt-2 w-80 bg-surface-elevated rounded-2xl shadow-xl border border-outline/60 overflow-hidden z-50"
          >
            <div className="flex items-center justify-between px-4 py-3 border-b border-outline/60">
              <span className="font-semibold text-sm text-content">Notifications</span>
              {unreadCount > 0 && (
                <button
                  onClick={() => markAllMutation.mutate()}
                  className="text-xs text-brand-500 hover:text-brand-600 font-medium"
                >
                  Mark all read
                </button>
              )}
            </div>

            {notifications.length === 0 ? (
              <div className="py-10 text-center text-sm text-content-subtle">
                No notifications yet
              </div>
            ) : (
              <div className="divide-y divide-outline/60">
                {notifications.map((n: any) => (
                  <div
                    key={n.id}
                    className={`flex items-start gap-3 px-4 py-3 transition-colors cursor-pointer hover:bg-surface ${
                      !n.isRead ? 'bg-brand-50/50' : ''
                    }`}
                    onClick={() => !n.isRead && markReadMutation.mutate(n.id)}
                  >
                    <div className={`w-2 h-2 rounded-full flex-shrink-0 mt-1.5 ${n.isRead ? 'bg-surface-sunken' : 'bg-brand-500'}`} />
                    <div className="flex-1 min-w-0">
                      <p className={`text-sm ${n.isRead ? 'text-content-muted' : 'text-content font-medium'}`}>
                        {n.title}
                      </p>
                      <p className="text-xs text-content-subtle mt-0.5 line-clamp-2">{n.message}</p>
                      <p className="text-[10px] text-content-subtle mt-1">
                        {new Date(n.createdAt).toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })}
                      </p>
                    </div>
                    {!n.isRead && (
                      <button
                        onClick={(e) => { e.stopPropagation(); markReadMutation.mutate(n.id); }}
                        className="p-1 text-content-subtle hover:text-brand-500 transition-colors flex-shrink-0"
                        title="Mark read"
                      >
                        <Check className="h-3.5 w-3.5" />
                      </button>
                    )}
                  </div>
                ))}
              </div>
            )}

            <div className="border-t border-outline/60 py-2.5 text-center">
              <Link
                to="/notifications"
                onClick={() => setOpen(false)}
                className="text-xs font-semibold text-brand-500 hover:text-brand-600"
              >
                View all notifications →
              </Link>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
