import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAppStore } from '@/store/useAppStore';
import { useNavigate } from 'react-router-dom';
import { Search, Home, ShoppingBag, User, Settings, Zap, X } from 'lucide-react';

interface Command {
  id: string;
  title: string;
  description: string;
  icon: React.ReactNode;
  action: () => void;
  category: string;
}

export const CommandPalette: React.FC = () => {
  const navigate = useNavigate();
  const commandPaletteOpen = useAppStore((state) => state.commandPaletteOpen);
  const setCommandPaletteOpen = useAppStore((state) => state.setCommandPaletteOpen);
  const [search, setSearch] = useState('');
  const [selectedIndex, setSelectedIndex] = useState(0);
  const inputRef = React.useRef<HTMLInputElement>(null);

  const commands: Command[] = [
    {
      id: '1',
      title: 'Home',
      description: 'Go to home page',
      icon: <Home className="w-4 h-4" />,
      action: () => navigate('/'),
      category: 'Navigation',
    },
    {
      id: '2',
      title: 'Products',
      description: 'Browse all products',
      icon: <ShoppingBag className="w-4 h-4" />,
      action: () => navigate('/products'),
      category: 'Navigation',
    },
    {
      id: '3',
      title: 'Cart',
      description: 'View your shopping cart',
      icon: <ShoppingBag className="w-4 h-4" />,
      action: () => navigate('/cart'),
      category: 'Navigation',
    },
    {
      id: '4',
      title: 'Profile',
      description: 'Go to your profile',
      icon: <User className="w-4 h-4" />,
      action: () => navigate('/profile'),
      category: 'Account',
    },
    {
      id: '5',
      title: 'Settings',
      description: 'Open settings',
      icon: <Settings className="w-4 h-4" />,
      action: () => navigate('/settings'),
      category: 'Account',
    },
    {
      id: '6',
      title: 'Loyalty Points',
      description: 'View loyalty program',
      icon: <Zap className="w-4 h-4" />,
      action: () => navigate('/loyalty'),
      category: 'Features',
    },
  ];

  const filtered = commands.filter(
    (cmd) =>
      cmd.title.toLowerCase().includes(search.toLowerCase()) ||
      cmd.description.toLowerCase().includes(search.toLowerCase())
  );

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setCommandPaletteOpen(!commandPaletteOpen);
      }

      if (!commandPaletteOpen) return;

      switch (e.key) {
        case 'Escape':
          setCommandPaletteOpen(false);
          break;
        case 'ArrowDown':
          e.preventDefault();
          setSelectedIndex((prev) => (prev + 1) % filtered.length);
          break;
        case 'ArrowUp':
          e.preventDefault();
          setSelectedIndex((prev) => (prev - 1 + filtered.length) % filtered.length);
          break;
        case 'Enter':
          e.preventDefault();
          if (filtered[selectedIndex]) {
            filtered[selectedIndex].action();
            setCommandPaletteOpen(false);
            setSearch('');
          }
          break;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [commandPaletteOpen, filtered, selectedIndex, setCommandPaletteOpen]);

  useEffect(() => {
    if (commandPaletteOpen) {
      inputRef.current?.focus();
    }
  }, [commandPaletteOpen]);

  useEffect(() => {
    setSelectedIndex(0);
  }, [search]);

  return (
    <AnimatePresence>
      {commandPaletteOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setCommandPaletteOpen(false)}
            className="fixed inset-0 bg-black/50 dark:bg-black/70 z-40"
          />

          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: -20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: -20 }}
            className="fixed top-1/4 left-1/2 -translate-x-1/2 w-full max-w-2xl bg-surface-elevated dark:bg-stone-900 rounded-xl shadow-2xl z-50 overflow-hidden border border-outline dark:border-stone-700"
          >
            {/* Search Input */}
            <div className="flex items-center px-4 py-3 border-b border-outline dark:border-stone-700">
              <Search className="w-5 h-5 text-content-subtle" />
              <input
                ref={inputRef}
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Type a command or search..."
                className="flex-1 ml-3 bg-transparent border-none outline-none text-content dark:text-content-subtle placeholder:text-content-muted"
              />
              <button
                onClick={() => setCommandPaletteOpen(false)}
                className="text-content-muted hover:text-content dark:hover:text-content-subtle"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Commands List */}
            <div className="max-h-96 overflow-y-auto">
              {filtered.length === 0 ? (
                <div className="p-8 text-center text-content-muted dark:text-content-subtle">
                  <p>No commands found</p>
                </div>
              ) : (
                <div>
                  {filtered.map((cmd, index) => (
                    <motion.button
                      key={cmd.id}
                      onClick={() => {
                        cmd.action();
                        setCommandPaletteOpen(false);
                        setSearch('');
                      }}
                      className={`w-full px-4 py-3 text-left flex items-center gap-3 transition-colors ${
                        selectedIndex === index
                          ? 'bg-brand-50 dark:bg-stone-800'
                          : 'hover:bg-surface dark:hover:bg-stone-800'
                      }`}
                      onMouseEnter={() => setSelectedIndex(index)}
                    >
                      <div className="text-brand-500">{cmd.icon}</div>
                      <div className="flex-1 min-w-0">
                        <p className="font-medium text-content dark:text-content-subtle truncate">{cmd.title}</p>
                        <p className="text-sm text-content-muted dark:text-content-subtle truncate">{cmd.description}</p>
                      </div>
                      <span className="text-xs px-2 py-1 rounded bg-surface-sunken dark:bg-stone-700 text-content-muted dark:text-content-subtle">
                        {cmd.category}
                      </span>
                    </motion.button>
                  ))}
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="px-4 py-3 border-t border-outline dark:border-stone-700 bg-surface dark:bg-stone-800 text-sm text-content-muted dark:text-content-subtle flex justify-between">
              <span>
                {filtered.length > 0 && (
                  <>
                    <kbd className="px-2 py-1 rounded bg-surface-sunken dark:bg-stone-700">↵</kbd> to select
                  </>
                )}
              </span>
              <span>
                <kbd className="px-2 py-1 rounded bg-surface-sunken dark:bg-stone-700">Esc</kbd> to close
              </span>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};
