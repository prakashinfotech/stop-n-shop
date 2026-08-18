/**
 * Validates that a banner Link URL points to a route the buyer-side router
 * actually serves. Returns null if the link is fine, or a short reason string
 * if it would dead-end. Source of truth is the route table in AppRouter.tsx
 * — keep these patterns in sync if new buyer routes are added.
 */

type RoutePattern = RegExp;

/**
 * Patterns supported on the buyer side. Every banner LinkUrl must match one,
 * be a valid external URL (http/https), or be empty (banner with no link).
 */
const SUPPORTED_PATTERNS: RoutePattern[] = [
  /^\/home$/,
  /^\/home\/products(\?.*)?$/,
  /^\/home\/products\/\d+$/,
  /^\/home\/product\/\d+$/,
  /^\/home\/category\/[a-z0-9-]+$/i,
  /^\/products\/\d+$/,           // legacy short path used in cart/order links
  /^\/user\/orders(\/\d+)?$/,
  /^\/user\/wishlist$/,
  /^\/user\/wallet$/,
  /^\/login$/,
  /^\/signup$/,
];

export interface LinkValidation {
  ok: boolean;
  reason?: string;
  /** Suggestion if we can confidently rewrite the input. */
  suggestion?: string;
}

export function validateBannerLink(raw: string | null | undefined): LinkValidation {
  const link = (raw ?? '').trim();
  if (link === '') return { ok: true }; // empty = banner is decorative, no nav

  // External URLs go through as-is.
  if (/^https?:\/\//i.test(link)) return { ok: true };

  if (!link.startsWith('/')) {
    return {
      ok: false,
      reason: 'Link must start with "/" (a relative app path) or be a full http(s) URL.',
    };
  }

  if (SUPPORTED_PATTERNS.some((re) => re.test(link))) return { ok: true };

  // Common rewrites — point legacy or pre-prefix paths at their real location.
  if (link.startsWith('/products') && !link.startsWith('/products/')) {
    return rewrite(link, link.replace(/^\/products/, '/home/products'));
  }
  if (link.startsWith('/category/')) {
    return rewrite(link, link.replace(/^\/category/, '/home/category'));
  }

  return {
    ok: false,
    reason: 'This route is not served by the buyer app. Use /home, /home/products, /home/category/<slug>, /home/products/<id>, etc.',
  };
}

function rewrite(input: string, suggestion: string): LinkValidation {
  return {
    ok: false,
    reason: `Route "${input}" no longer exists — buyer routes are namespaced under /home/*.`,
    suggestion,
  };
}
