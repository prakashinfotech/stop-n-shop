import React from 'react';
import { Link } from 'react-router-dom';
import { Instagram, Facebook, Twitter, Youtube, MapPin, Phone, Mail } from 'lucide-react';

const FOOTER_LINKS = {
  'Company': [
    { label: 'About Us', href: '/about' },
    { label: 'Careers', href: '/careers' },
    { label: 'Press', href: '/press' },
    { label: 'Store Locator', href: '/stores' },
  ],
  'Help': [
    { label: 'FAQ', href: '/faq' },
    { label: 'Shipping & Returns', href: '/shipping' },
    { label: 'Size Guide', href: '/size-guide' },
    { label: 'Track Order', href: '/track-order' },
  ],
  'Policies': [
    { label: 'Privacy Policy', href: '/privacy' },
    { label: 'Terms of Use', href: '/terms' },
    { label: 'Cookie Policy', href: '/cookies' },
    { label: 'Accessibility', href: '/accessibility' },
  ],
};

const SOCIAL = [
  { Icon: Instagram, href: '#', label: 'Instagram' },
  { Icon: Facebook,  href: '#', label: 'Facebook' },
  { Icon: Twitter,   href: '#', label: 'Twitter' },
  { Icon: Youtube,   href: '#', label: 'YouTube' },
];

export const Footer: React.FC = () => (
  <footer className="bg-stone-900 text-stone-300">
    {/* Main footer */}
    <div className="max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8 py-14">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-8">
        {/* Brand column */}
        <div className="lg:col-span-2">
          <Link to="/home" className="inline-block mb-4">
            <span className="font-display text-2xl font-bold text-white">
              Stop<span className="text-brand-400">N</span>Shop
            </span>
          </Link>
          <p className="text-sm text-stone-400 leading-relaxed mb-6 max-w-xs">
            India's premium fashion destination. Curating the finest styles for every occasion since 2024.
          </p>
          {/* Contact */}
          <div className="space-y-2 text-sm">
            <div className="flex items-center gap-2 text-stone-400">
              <MapPin className="h-4 w-4 flex-shrink-0" />
              <span>123 Fashion Street, Ahmedabad, GJ 380006</span>
            </div>
            <div className="flex items-center gap-2 text-stone-400">
              <Phone className="h-4 w-4 flex-shrink-0" />
              <span>1800-XXX-XXXX (Toll Free)</span>
            </div>
            <div className="flex items-center gap-2 text-stone-400">
              <Mail className="h-4 w-4 flex-shrink-0" />
              <span>care@stopnshop.in</span>
            </div>
          </div>
          {/* Social */}
          <div className="flex gap-3 mt-6">
            {SOCIAL.map(({ Icon, href, label }) => (
              <a
                key={label}
                href={href}
                aria-label={label}
                className="p-2 rounded-full bg-stone-800 hover:bg-brand-500 text-stone-400 hover:text-white transition-colors"
              >
                <Icon className="h-4 w-4" />
              </a>
            ))}
          </div>
        </div>

        {/* Link columns */}
        {Object.entries(FOOTER_LINKS).map(([heading, links]) => (
          <div key={heading}>
            <h3 className="text-white font-semibold text-sm uppercase tracking-wider mb-4">
              {heading}
            </h3>
            <ul className="space-y-2">
              {links.map((link) => (
                <li key={link.label}>
                  <Link
                    to={link.href}
                    className="text-sm text-stone-400 hover:text-white transition-colors"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
    </div>

    {/* Bottom bar */}
    <div className="border-t border-stone-800">
      <div className="max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex flex-col sm:flex-row items-center justify-between gap-2 text-xs text-stone-500">
        <span>© {new Date().getFullYear()} StopNShop. All rights reserved.</span>
        <div className="flex items-center gap-4">
          <span>We accept:</span>
          {['Visa', 'Mastercard', 'UPI', 'NetBanking'].map((method) => (
            <span
              key={method}
              className="bg-stone-800 text-stone-300 px-2 py-0.5 rounded text-[10px] font-medium"
            >
              {method}
            </span>
          ))}
        </div>
      </div>
    </div>
  </footer>
);
