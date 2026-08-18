import React, { useState, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { MapPin, Phone, ExternalLink, Smartphone } from 'lucide-react';
import { Drawer } from '../../components/ui/Drawer';
import { catalogueApi } from '../../api/catalogueApi';

interface StoreLocatorDrawerProps {
  open: boolean;
  onClose: () => void;
}

export const StoreLocatorDrawer: React.FC<StoreLocatorDrawerProps> = ({ open, onClose }) => {
  const [selectedCity, setSelectedCity] = useState('');

  const { data: stores = [], isLoading } = useQuery({
    queryKey: ['stores'],
    queryFn: () => catalogueApi.getStores().then((r) => r.data.data),
    enabled: open,
  });

  const cities = useMemo(
    () => Array.from(new Set(stores.map((s) => s.city))).sort(),
    [stores]
  );

  const filtered = selectedCity
    ? stores.filter((s) => s.city === selectedCity)
    : stores;

  return (
    <Drawer open={open} onClose={onClose} title="Find Shop N Shop near you" width="max-w-lg">
      <div className="p-5 space-y-5">
        {/* City filter */}
        <select
          value={selectedCity}
          onChange={(e) => setSelectedCity(e.target.value)}
          className="w-full border border-outline rounded-xl px-4 py-2.5 text-sm focus:outline-none focus:border-brand-400 focus:ring-1 focus:ring-brand-200"
        >
          <option value="">All Cities</option>
          {cities.map((city) => (
            <option key={city} value={city}>{city}</option>
          ))}
        </select>

        {/* Store list */}
        {isLoading ? (
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-24 bg-surface-sunken rounded-xl animate-pulse" />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <p className="text-center text-content-muted py-8 text-sm">No stores found in this city.</p>
        ) : (
          <div className="space-y-3">
            {filtered.map((store) => (
              <div key={store.id} className="border border-outline/60 rounded-xl p-4 space-y-2">
                <p className="font-semibold text-content text-sm">{store.name}</p>
                <div className="flex items-start gap-2 text-xs text-content-muted">
                  <MapPin className="h-3.5 w-3.5 mt-0.5 flex-shrink-0 text-brand-500" />
                  <span>{store.address}, {store.city}, {store.state}</span>
                </div>
                <div className="flex items-center gap-2 text-xs text-content-muted">
                  <Phone className="h-3.5 w-3.5 flex-shrink-0 text-brand-500" />
                  <span>{store.phone}</span>
                </div>
                <a
                  href={`https://www.google.com/maps?q=${store.lat},${store.lng}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1.5 text-xs font-semibold text-brand-500 hover:underline"
                >
                  <ExternalLink className="h-3 w-3" />
                  Get Directions
                </a>
              </div>
            ))}
          </div>
        )}

        {/* App CTA */}
        <div className="border-t border-outline/60 pt-4">
          <a
            href="https://play.google.com/store/apps/details?id=shoppersstop.shoppersstop&hl=en&pli=1"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center justify-center gap-2 w-full bg-stone-900 hover:bg-brand-500 text-white rounded-xl py-3 text-sm font-semibold transition-colors"
          >
            <Smartphone className="h-4 w-4" />
            Get the App
          </a>
        </div>
      </div>
    </Drawer>
  );
};
