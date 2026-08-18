import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { Send, X, MessageCircle, ArrowUpRight, Sparkles, AlertCircle, Check } from 'lucide-react';
import { useAppStore } from '@/store/useAppStore';
import { parseAriaIntent, type AriaAction, type AriaMode } from '@/lib/ariaIntent';
import { complaintsApi, type ComplaintCategory } from '@/api/complaintsApi';
import { useAuthContext } from '@/context/AuthContext';
import { useToast } from '@/components/ui/Toast';
import { snoozePendingOrderNudge } from '@/hooks/usePendingOrderNudge';

interface Message {
  id: string;
  role: 'aria' | 'user';
  content: string;
  ts: number;
  /** Optional CTA chip that the bot can attach to its message (e.g. "Open results"). */
  cta?: { label: string; href?: string; onClick?: () => void };
  /** Quick-reply chips shown under a bot message. */
  suggestions?: string[];
  /** Optional badge / icon mode for the bubble (success, info, etc). */
  tone?: 'default' | 'success' | 'info';
}

type ComplaintStage =
  | { stage: 'idle' }
  | { stage: 'category' }
  | { stage: 'subject';  category: ComplaintCategory }
  | { stage: 'body';     category: ComplaintCategory; subject: string }
  | { stage: 'confirm';  category: ComplaintCategory; subject: string; body: string }
  | { stage: 'sent';     id: number };

const CATEGORY_BY_LABEL: Record<string, ComplaintCategory> = {
  'delivery':            'delivery',
  'product quality':     'product',
  'product':             'product',
  'payment / refund':    'payment',
  'payment':             'payment',
  'account':             'account',
  'something else':      'other',
  'other':               'other',
};

const fmtTime = (ts: number) =>
  new Date(ts).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

export const AIAgentDrawer: React.FC = () => {
  const ariaOpen        = useAppStore((s) => s.ariaOpen);
  const setAriaOpen     = useAppStore((s) => s.setAriaOpen);
  const pendingNudge    = useAppStore((s) => s.pendingAriaNudge);
  const consumeNudge    = useAppStore((s) => s.consumeAriaNudge);
  const navigate        = useNavigate();
  const { pathname } = useLocation();
  const { user }    = useAuthContext();
  const { showToast } = useToast();

  // Role-aware mode. Admins don't see Aria at all; sellers get the seller flow guide,
  // everyone else (buyers + signed-out visitors) gets the shopping assistant.
  const isAdmin  = user?.role === 'Admin';
  const isSeller = user?.role === 'Seller';
  const mode: AriaMode = isSeller ? 'seller' : 'buyer';

  const sellerIntro =
    `Hi ${user?.firstName ?? 'there'} — I'm Aria, your seller-side guide. ` +
    `Ask me how to add a product, confirm orders, print labels, or anything else about the seller module.`;
  const buyerIntro =
    user
      ? `Hi ${user.firstName ?? 'there'} — I'm Aria. I can help you find products, track an order, or raise a complaint.`
      : "Hi — I'm Aria. I can help you find products, track an order, or raise a complaint.";

  const sellerSuggestions = [
    'How do I add a warehouse?',
    'How do I list a product?',
    'Where do I confirm orders?',
    'When do I get paid?',
  ];
  const buyerSuggestions = [
    'Party wear for the weekend',
    'Formal shirts for office',
    'Where is my order?',
    'I have a complaint',
  ];

  const [messages, setMessages] = useState<Message[]>(() => [{
    id: 'm1', role: 'aria', ts: Date.now(),
    content: isSeller ? sellerIntro : buyerIntro,
    suggestions: isSeller ? sellerSuggestions : buyerSuggestions,
  }]);
  const [input, setInput]       = useState('');
  const [typing, setTyping]     = useState(false);
  const [complaint, setComplaint] = useState<ComplaintStage>({ stage: 'idle' });

  const bottomRef = useRef<HTMLDivElement>(null);
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'smooth' }); }, [messages, typing]);

  // Consume proactive nudges pushed by hooks like usePendingOrderNudge.
  // Push as an Aria message, pop the drawer open, then clear the pending state.
  // The dedupe lives in the store so re-renders here can't double-fire.
  useEffect(() => {
    if (!pendingNudge) return;
    setMessages((prev) => [
      ...prev,
      {
        id:          pendingNudge.id,
        role:        'aria',
        ts:          Date.now(),
        content:     pendingNudge.content,
        cta:         pendingNudge.cta ? { label: pendingNudge.cta.label, href: pendingNudge.cta.href } : undefined,
        suggestions: pendingNudge.suggestions,
        tone:        pendingNudge.tone ?? 'info',
      },
    ]);
    setAriaOpen(true);
    consumeNudge();
  }, [pendingNudge, setAriaOpen, consumeNudge]);

  // ── Helpers ──────────────────────────────────────────────────────────
  const push = useCallback((m: Omit<Message, 'id' | 'ts'>) => {
    setMessages((prev) => [...prev, { id: `m${prev.length + 1}-${Date.now()}`, ts: Date.now(), ...m }]);
  }, []);

  const askAria = useCallback(async (raw: string) => {
    const text = raw.trim();
    if (!text) return;
    push({ role: 'user', content: text });
    setInput('');
    setTyping(true);

    // Tiny think-time so the typing indicator is visible (and pleasant).
    await new Promise((r) => setTimeout(r, 350));

    try {
      if (complaint.stage !== 'idle' && complaint.stage !== 'sent') {
        await advanceComplaint(text);
      } else {
        await dispatchIntent(text);
      }
    } finally {
      setTyping(false);
    }
  }, [complaint, push]); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Intent dispatch ──────────────────────────────────────────────────
  const dispatchIntent = async (text: string) => {
    const action: AriaAction = parseAriaIntent(text, mode);

    if (action.kind === 'complaint') {
      setComplaint({ stage: 'category' });
      push({
        role: 'aria',
        content: action.reply,
        suggestions: action.suggestions,
        tone: 'info',
      });
      return;
    }

    push({
      role: 'aria',
      content: action.reply,
      suggestions: action.suggestions,
      cta: action.href
        ? { label: 'Open', href: action.href }
        : undefined,
    });
  };

  // ── Complaint sub-flow ───────────────────────────────────────────────
  const advanceComplaint = async (text: string) => {
    if (complaint.stage === 'category') {
      const key = text.toLowerCase();
      const matched = (Object.keys(CATEGORY_BY_LABEL) as string[]).find((k) => key.includes(k));
      const category = matched ? CATEGORY_BY_LABEL[matched] : 'other';
      setComplaint({ stage: 'subject', category });
      push({
        role: 'aria',
        content: `Got it — logging this under **${category}**. Give it a short title (e.g. "Wrong item delivered in order SNS-…").`,
        tone: 'info',
      });
      return;
    }

    if (complaint.stage === 'subject') {
      if (text.length < 3) {
        push({ role: 'aria', content: 'Title needs to be at least 3 characters. Try again.' });
        return;
      }
      setComplaint({ stage: 'body', category: complaint.category, subject: text });
      push({ role: 'aria', content: 'Now a few lines on what happened — the more detail, the faster we can help.' });
      return;
    }

    if (complaint.stage === 'body') {
      if (text.length < 10) {
        push({ role: 'aria', content: 'A bit more detail please — at least 10 characters.' });
        return;
      }
      setComplaint({ stage: 'confirm', category: complaint.category, subject: complaint.subject, body: text });
      push({
        role: 'aria',
        content: `Ready to submit. Send "yes" to file it, or "edit" to start over.`,
        suggestions: ['Yes, submit', 'Edit'],
      });
      return;
    }

    if (complaint.stage === 'confirm') {
      if (/^(no|edit|cancel|restart)/i.test(text)) {
        setComplaint({ stage: 'idle' });
        push({ role: 'aria', content: "OK, scrapped that. Tell me again what's wrong and we'll start over." });
        return;
      }
      try {
        const res = await complaintsApi.create({
          category: complaint.category,
          subject:  complaint.subject,
          body:     complaint.body,
          source:   'aria',
        });
        const id = res.data.data?.complaintId ?? 0;
        setComplaint({ stage: 'sent', id });
        push({
          role: 'aria',
          content: `Filed as complaint #${id}. You'll get a notification when the team responds.`,
          tone: 'success',
          suggestions: ['Browse products', 'Track my order'],
        });
        showToast('Complaint filed', 'success');
      } catch (e: any) {
        push({
          role: 'aria',
          content: `Couldn't file it: ${e?.response?.data?.message ?? 'something went wrong'}. You can try again.`,
        });
      }
      return;
    }
  };

  // ── Chip click handlers ──────────────────────────────────────────────
  // "Snooze 1h" is intercepted as a side-effect — write the snooze timestamp
  // and acknowledge in-line instead of sending it through the intent parser.
  const onSuggest = (s: string) => {
    if (s === 'Snooze 1h') {
      snoozePendingOrderNudge();
      push({
        role: 'aria',
        tone: 'success',
        content: "OK — I'll keep quiet about pending orders for the next hour.",
      });
      return;
    }
    askAria(s);
  };
  const onCta = (cta: NonNullable<Message['cta']>) => {
    if (cta.onClick) cta.onClick();
    if (cta.href) {
      navigate(cta.href);
      setAriaOpen(false);
    }
  };

  // Admin + Dispatcher sessions don't see Aria. Both are operations-internal
  // roles — Aria's buyer/seller persona isn't relevant to them.
  if (isAdmin) return null;
  if (user?.role === 'Dispatcher') return null;

  // Hide Aria on auth/onboarding flows + the entire dispatcher portal (the
  // mobile-first layout has no room for the chat bubble and dispatchers
  // shouldn't be talking to a buyer-style assistant on the job).
  const AUTH_PATH_PATTERNS = [
    '/login', '/register', '/signup', '/forgot', '/reset', '/otp',
    '/user/login', '/seller/login', '/admin/login', '/dispatch/login',
    '/seller/register', '/seller/signup', '/seller/onboarding',
    '/dispatch',
  ];
  if (AUTH_PATH_PATTERNS.some((p) => pathname.startsWith(p) || pathname.endsWith(p))) {
    return null;
  }

  // ── Render ───────────────────────────────────────────────────────────
  return (
    <AnimatePresence>
      {ariaOpen && (
        <motion.div
          key="aria-panel"
          initial={{ opacity: 0, y: 24, scale: 0.98 }}
          animate={{ opacity: 1, y: 0,  scale: 1 }}
          exit={{    opacity: 0, y: 24, scale: 0.98 }}
          transition={{ type: 'spring', damping: 22, stiffness: 300 }}
          className="fixed bottom-4 right-4 w-[380px] max-w-[calc(100vw-2rem)] h-[640px] max-h-[calc(100vh-2rem)] z-50
                     bg-surface-elevated dark:bg-stone-950 rounded-2xl shadow-2xl flex flex-col
                     border border-outline/80 overflow-hidden"
        >
          {/* Header — claude-style: warm cream, calm */}
          <header className="flex items-center justify-between px-4 py-3 border-b border-outline/60 bg-bg">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-9 h-9 rounded-full bg-brand-500 text-white flex items-center justify-center flex-shrink-0">
                <Sparkles className="h-4 w-4" />
              </div>
              <div className="min-w-0">
                <p className="font-semibold text-content leading-tight">Aria</p>
                <p className="text-[11px] text-content-muted leading-tight">
                  {isSeller ? 'Seller guide · always available' : 'Shopping assistant · always available'}
                </p>
              </div>
            </div>
            <button
              onClick={() => setAriaOpen(false)}
              aria-label="Close Aria"
              className="p-1.5 rounded-lg text-content-muted hover:text-content hover:bg-surface-sunken transition-colors"
            >
              <X className="h-5 w-5" />
            </button>
          </header>

          {/* Messages */}
          <div className="flex-1 overflow-y-auto px-4 py-5 space-y-4 bg-bg">
            {messages.map((m) => (
              <MessageBubble key={m.id} message={m} onCta={onCta} onSuggest={onSuggest} />
            ))}
            {typing && <TypingDots />}
            <div ref={bottomRef} />
          </div>

          {/* Input */}
          <form
            onSubmit={(e) => { e.preventDefault(); askAria(input); }}
            className="border-t border-outline/60 bg-surface-elevated px-3 py-3"
          >
            <div className="flex items-end gap-2 rounded-2xl border border-outline-strong bg-surface px-3 py-2 focus-within:ring-2 focus-within:ring-brand-200 transition-shadow">
              <textarea
                rows={1}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    askAria(input);
                  }
                }}
                placeholder={isSeller
                  ? 'Ask Aria — try "how do I add a warehouse?"'
                  : 'Ask Aria — try "gift for her under 1500"'}
                className="flex-1 resize-none bg-transparent outline-none text-sm text-content placeholder:text-content-subtle leading-6 max-h-28"
              />
              <button
                type="submit"
                aria-label="Send"
                disabled={!input.trim() || typing}
                className="w-9 h-9 rounded-xl bg-brand-500 text-white flex items-center justify-center hover:bg-brand-600 disabled:opacity-40 disabled:cursor-not-allowed transition-colors flex-shrink-0"
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
            <p className="mt-1.5 text-[10px] text-content-subtle text-center">
              Aria runs locally — answers don't leave your session.
            </p>
          </form>
        </motion.div>
      )}

      {/* Floating launcher */}
      <motion.button
        key="aria-fab"
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={() => setAriaOpen(!ariaOpen)}
        className={`fixed bottom-4 right-4 w-14 h-14 rounded-full flex items-center justify-center shadow-lg transition-all z-40
                    ring-2 ring-white/40 ${ariaOpen
                      ? 'opacity-0 pointer-events-none'
                      : 'bg-brand-500 text-white hover:bg-brand-600 hover:shadow-xl'}`}
        aria-label="Open Aria"
      >
        <MessageCircle className="w-6 h-6" />
      </motion.button>
    </AnimatePresence>
  );
};

// ── Bubble + supporting bits ───────────────────────────────────────────────

const MessageBubble: React.FC<{
  message: Message;
  onCta: (cta: NonNullable<Message['cta']>) => void;
  onSuggest: (s: string) => void;
}> = ({ message, onCta, onSuggest }) => {
  if (message.role === 'user') {
    return (
      <div className="flex justify-end">
        <div className="max-w-[78%] bg-brand-500 text-white rounded-2xl rounded-br-md px-3.5 py-2 shadow-sm">
          <p className="text-sm leading-relaxed whitespace-pre-wrap">{message.content}</p>
          <p className="text-[10px] opacity-70 mt-1 text-right">{fmtTime(message.ts)}</p>
        </div>
      </div>
    );
  }

  const toneBorder = message.tone === 'info'    ? 'border-amber-200/60'
                    : message.tone === 'success' ? 'border-emerald-200/60'
                    : 'border-outline/70';

  return (
    <div className="flex items-start gap-2">
      <div className="w-7 h-7 rounded-full bg-brand-500/10 text-brand-600 flex items-center justify-center flex-shrink-0 mt-0.5">
        {message.tone === 'success'
          ? <Check className="h-3.5 w-3.5" />
          : message.tone === 'info'
            ? <AlertCircle className="h-3.5 w-3.5" />
            : <Sparkles className="h-3.5 w-3.5" />}
      </div>
      <div className="flex-1 min-w-0 space-y-2">
        <div className={`max-w-[88%] bg-surface-elevated text-content rounded-2xl rounded-tl-md px-3.5 py-2 border ${toneBorder} shadow-sm`}>
          <p className="text-sm leading-relaxed whitespace-pre-wrap">{renderInline(message.content)}</p>
          <p className="text-[10px] text-content-subtle mt-1">{fmtTime(message.ts)}</p>
        </div>

        {message.cta && (
          <div>
            <button
              onClick={() => onCta(message.cta!)}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-brand-500 text-white text-xs font-semibold hover:bg-brand-600 transition-colors shadow-sm"
            >
              {message.cta.label}
              <ArrowUpRight className="h-3.5 w-3.5" />
            </button>
          </div>
        )}

        {message.suggestions && message.suggestions.length > 0 && (
          <div className="flex flex-wrap gap-1.5">
            {message.suggestions.map((s) => (
              <button
                key={s}
                onClick={() => onSuggest(s)}
                className="px-2.5 py-1 rounded-full text-[11px] border border-outline text-content-muted hover:text-content hover:border-brand-300 hover:bg-brand-50 transition-colors"
              >
                {s}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

const TypingDots: React.FC = () => (
  <div className="flex items-center gap-2">
    <div className="w-7 h-7 rounded-full bg-brand-500/10 text-brand-600 flex items-center justify-center">
      <Sparkles className="h-3.5 w-3.5" />
    </div>
    <div className="bg-surface-elevated border border-outline/70 rounded-2xl rounded-tl-md px-3 py-2 shadow-sm">
      <div className="flex gap-1">
        {[0, 1, 2].map((i) => (
          <motion.span
            key={i}
            animate={{ y: [0, -3, 0], opacity: [0.4, 1, 0.4] }}
            transition={{ duration: 1, repeat: Infinity, delay: i * 0.15 }}
            className="w-1.5 h-1.5 bg-brand-500 rounded-full"
          />
        ))}
      </div>
    </div>
  </div>
);

/** Bare-minimum inline markdown: **bold**. Plain text otherwise. */
function renderInline(text: string): React.ReactNode {
  const parts: React.ReactNode[] = [];
  let i = 0;
  const re = /\*\*([^*]+)\*\*/g;
  let m: RegExpExecArray | null;
  let cursor = 0;
  while ((m = re.exec(text)) !== null) {
    if (m.index > cursor) parts.push(text.slice(cursor, m.index));
    parts.push(<strong key={`b${i++}`} className="font-semibold">{m[1]}</strong>);
    cursor = m.index + m[0].length;
  }
  if (cursor < text.length) parts.push(text.slice(cursor));
  return parts;
}
