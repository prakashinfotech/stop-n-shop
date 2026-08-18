/**
 * Rule-based intent parser for the Aria shopping assistant.
 *
 * Goals:
 *  - Take a free-text buyer message and produce a concrete action: either a
 *    storefront URL with filters applied, or a chat-state transition (e.g. start
 *    a complaint flow).
 *  - Stay LLM-free for the eval. The mapping is keyword + phrase based, ordered
 *    by specificity so "complain about my order" beats the generic "order" hit.
 *  - Easy to extend: add a new entry to one of the dictionaries below.
 */

export type AriaActionKind =
  | 'navigate'        // open a URL in the storefront
  | 'complaint'       // begin/advance the complaint sub-flow
  | 'help'            // show a help message with quick chips
  | 'order_status'    // jump to /user/orders
  | 'wallet'          // jump to /user/wallet
  | 'wishlist'        // jump to /user/wishlist
  | 'cart'            // jump to /user/cart
  | 'small_talk';     // generic friendly response

export interface AriaAction {
  kind: AriaActionKind;
  /** Short, user-facing reply rendered by the chatbot. */
  reply: string;
  /** Optional URL — when present the UI offers a CTA chip to open it. */
  href?: string;
  /** Optional follow-up suggestion chips. */
  suggestions?: string[];
  /** Free-form metadata (filter slices extracted from the prompt, etc). */
  meta?: Record<string, string | number | undefined>;
}

// ── Dictionaries ──────────────────────────────────────────────────────────

/**
 * Maps free-text keywords to a (categorySlug, subCategoryTag) hint.
 * Slugs match the seeded category data (see Seed_Categories.sql).
 */
const CATEGORY_KEYWORDS: { match: RegExp; tag: string; label: string }[] = [
  { match: /\b(dress|gown|frock)\b/i,                       tag: 'dress',     label: 'dresses' },
  { match: /\b(shirt|t[- ]?shirt|tee|polo|blouse|top)\b/i,   tag: 'shirt',     label: 'shirts & tops' },
  { match: /\b(jean|jeans|trouser|pant|chino)\b/i,           tag: 'jeans',     label: 'jeans & trousers' },
  { match: /\b(saree|kurta|ethnic|lehenga|sherwani)\b/i,     tag: 'ethnic',    label: 'ethnic wear' },
  { match: /\b(shoe|sneaker|sandal|boot|heel|loafer)\b/i,    tag: 'footwear',  label: 'footwear' },
  { match: /\b(bag|backpack|handbag|wallet)\b/i,             tag: 'bag',       label: 'bags' },
  { match: /\b(watch|smartwatch)\b/i,                        tag: 'watch',     label: 'watches' },
  { match: /\b(perfume|fragrance|cologne|deo)\b/i,           tag: 'fragrance', label: 'fragrances' },
  { match: /\b(makeup|lipstick|skincare|beauty)\b/i,         tag: 'beauty',    label: 'beauty' },
  { match: /\b(toy|game|playset)\b/i,                        tag: 'toy',      label: 'toys' },
];

const GENDER_KEYWORDS: { match: RegExp; id: number; label: string }[] = [
  { match: /\b(men|man|male|him|his|boyfriend|husband|dad|father|gent|guys?)\b/i, id: 1, label: 'Men' },
  { match: /\b(women|woman|female|her|she|girlfriend|wife|mom|mother|ladies)\b/i,  id: 2, label: 'Women' },
  { match: /\b(kids?|child|children|boy|girl|baby|toddler|son|daughter)\b/i,       id: 3, label: 'Kids' },
  { match: /\b(unisex)\b/i,                                                         id: 4, label: 'Unisex' },
];

/** Occasion / vibe tags. Mapped to the `tags` field on the search endpoint. */
const OCCASION_TAGS: { match: RegExp; tag: string }[] = [
  { match: /\b(office|work|formal|workwear|interview|business)\b/i,       tag: 'formal'    },
  { match: /\b(party|cocktail|night[- ]?out|club|date)\b/i,                tag: 'party'     },
  { match: /\b(wedding|reception|sangeet|haldi|mehendi)\b/i,                tag: 'wedding'   },
  { match: /\b(casual|everyday|relax|weekend|lounge)\b/i,                   tag: 'casual'    },
  { match: /\b(birthday|anniversary|gift|present)\b/i,                      tag: 'gifting'   },
  { match: /\b(sport|gym|workout|running|fitness|athletic|athleisure)\b/i,  tag: 'sport'     },
  { match: /\b(summer|winter|monsoon|festive|festival|diwali|holi|eid)\b/i, tag: 'seasonal'  },
];

const PRICE_PATTERNS: { match: RegExp; key: 'maxPrice' | 'minPrice' }[] = [
  { match: /\b(?:under|below|less than|<\s*)(?:rs\.?|₹|inr)?\s*(\d{2,6})\b/i,    key: 'maxPrice' },
  { match: /\b(?:within|upto|up to)\s*(?:rs\.?|₹|inr)?\s*(\d{2,6})\b/i,           key: 'maxPrice' },
  { match: /\b(?:above|over|more than|>\s*)(?:rs\.?|₹|inr)?\s*(\d{2,6})\b/i,       key: 'minPrice' },
];

// ── Special intents (complaints, navigation shortcuts) ────────────────────

const COMPLAINT_RE = /\b(complaint|complain|issue|problem|defective|damaged|wrong\s+item|not\s+received|missing|refund|return\s+request|delay(?:ed)?|stuck|help\s+me\s+with\s+an?\s+issue|raise\s+(?:a\s+)?(?:ticket|complaint))\b/i;
const ORDER_RE     = /\b(?:track|where\s+is|status\s+of)\s+(?:my\s+)?orders?\b|\bmy\s+orders?\b/i;
const WALLET_RE    = /\b(?:wallet|balance|refunds?|credits?|cashback)\b/i;
const WISHLIST_RE  = /\b(wishlist|saved\s+items?|favourites?)\b/i;
const CART_RE      = /\bcart\b/i;
const GREETING_RE  = /^(hi|hello|hey|yo|hola|namaste|good\s+(?:morning|evening|afternoon))[\s!.]*$/i;

// ── Seller dictionary ────────────────────────────────────────────────────

export type AriaMode = 'buyer' | 'seller';

/**
 * Seller how-to entries. Each test() regex is a pattern the seller might
 * actually type; the response combines a short answer with a CTA chip.
 * Order matters — list more specific matches before generic ones.
 */
const SELLER_HOWTOS: { match: RegExp; build: () => AriaAction }[] = [
  {
    match: /\b(add|create|new|set\s*up).{0,20}\bwarehouse(s)?\b|\bwarehouse(s)?\b.{0,15}\b(add|create|new)\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'To add a warehouse:\n' +
        '1. Open **Warehouses** in the seller sidebar.\n' +
        '2. Click **Add warehouse** and fill in name, pickup address, and pincode.\n' +
        '3. Mark the first one **Primary** — that\'s where new stock defaults to.\n\n' +
        'Want me to open it?',
      href: '/seller/warehouses',
      suggestions: ['How do I add products?', 'Where do I confirm orders?'],
    }),
  },
  {
    match: /\b(add|create|new|list|upload).{0,20}\bproduct(s)?\b|\bproduct(s)?\b.{0,15}\b(add|create|list)\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'Adding a product is a 6-step wizard:\n' +
        '1. Pick **Menu → Category → Subcategory**.\n' +
        '2. **Basics** — name, description, brand, gender (if asked).\n' +
        '3. **Pricing** — MRP, selling price, stock.\n' +
        '4. **Variants** — the chips you see are the admin-curated library; untick what doesn\'t apply.\n' +
        '5. **Media** — upload one image per labeled slot (front/back/etc).\n' +
        '6. **Review** and submit.\n\n' +
        'Drafts auto-save while you work.',
      href: '/seller/products/new',
      suggestions: ['How do variants work?', 'How do I print labels?'],
    }),
  },
  {
    match: /\b(confirm|accept|reject|fulfil|fulfill).{0,20}\border(s)?\b|\border(s)?.{0,15}(queue|fulfilment|fulfillment)\b|\bfulfilment\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'Use the **Fulfilment Queue** to act on incoming orders:\n' +
        '• **Pending** tab → tap **Confirm** on each line, or **Reject** with a reason (≥10 chars).\n' +
        '• Reject restocks the variant and refunds the buyer\'s wallet if they prepaid.\n' +
        '• Once confirmed, a **Print label** chip appears for the sticker + receipt.',
      href: '/seller/orders/queue',
      suggestions: ['How do I print a label?', 'What does Settlement mean?'],
    }),
  },
  {
    match: /\b(print|sticker|label|barcode|receipt)\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'After you confirm an item, the row in the Fulfilment Queue gets a **Print label** button. It opens an A6 shipping sticker (Code128 + QR + To/From address) and an A4 invoice. Use the dropdown to pick **Sticker / Receipt / Both** before printing.',
      href: '/seller/orders/queue',
      suggestions: ['Where do I see orders?', 'How do I update stock?'],
    }),
  },
  {
    match: /\b(low\s*stock|inventory|stock\s*level|out\s*of\s*stock)\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'The **Inventory** page shows per-variant stock per warehouse with low-stock alerts. Tap the row to adjust quantity or move stock between warehouses.',
      href: '/seller/inventory',
      suggestions: ['How do I add a warehouse?', 'How do variants work?'],
    }),
  },
  {
    match: /\b(settlement|payout|payments?\s+to\s+me|when\s+do\s+i\s+get\s+paid|earnings?)\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'Settlements run on a **T+7 cycle** — delivered orders settle 7 days after delivery. Open **Settlements** to see each statement\'s line items, commission, and TDS. Make sure your **Bank Accounts** has one row marked Primary or payouts can\'t be initiated.',
      href: '/seller/settlements',
      suggestions: ['Add a bank account', 'Show my performance score'],
    }),
  },
  {
    match: /\b(bank|account|ifsc|upi)\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'Open **Bank Accounts** to add an IFSC + account number. Mark exactly one as **Primary** — that\'s where settlements get sent.',
      href: '/seller/bank-accounts',
      suggestions: ['What is a settlement?', 'Show my performance score'],
    }),
  },
  {
    match: /\b(performance|score|rating|seller\s+rating)\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'Your **Performance Score** card on the dashboard tracks rolling-30-day delivery rate, cancellation rate, and average rating. Lower scores cap your visibility on PLPs.',
      href: '/seller/dashboard',
      suggestions: ['Settlements', 'How to reduce rejections?'],
    }),
  },
  {
    match: /\b(dashboard|analytics|insights|sales|stats|revenue)\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'The **Dashboard** widgets are live and click-through: KPI cards open the underlying list filtered to the right state.',
      href: '/seller/dashboard',
      suggestions: ['Settlements', 'Fulfilment queue'],
    }),
  },
  {
    match: /\b(onboard|kyc|gst|gst\s*number|pan|verify)\b/i,
    build: () => ({
      kind: 'navigate',
      reply:
        'Onboarding has six stages — verification, categories, store details, pickup address, bank, agreement. Complete each one in **Profile** to unlock product listing.',
      href: '/seller/profile',
      suggestions: ['Add a warehouse', 'How do I add products?'],
    }),
  },
  {
    match: /\b(variant|size|colou?r\s*chip|attribute)\b/i,
    build: () => ({
      kind: 'small_talk',
      reply:
        'Variant chips on the Add Product wizard come from the **admin-curated library** for each subcategory. You untick the ones that don\'t apply to your product (e.g. uncheck XXL if you don\'t carry it).',
      suggestions: ['How do I add a product?', 'How do I add a warehouse?'],
    }),
  },
];

/** Single, friendly catch-all listing seller capabilities. */
const SELLER_HELP_REPLY =
  "I can help you with:\n" +
  "• Adding products, warehouses, bank accounts\n" +
  "• Confirming or rejecting orders\n" +
  "• Printing shipping labels & receipts\n" +
  "• Settlements, inventory, performance score\n" +
  "• Filing a complaint with the platform\n\n" +
  "What do you want to do?";

const SELLER_SUGGESTIONS = [
  'How do I add a warehouse?',
  'How do I list a product?',
  'Where do I confirm orders?',
  'When do I get paid?',
];

// ── Public API ────────────────────────────────────────────────────────────

export function parseAriaIntent(rawInput: string, mode: AriaMode = 'buyer'): AriaAction {
  const text = (rawInput ?? '').trim();
  if (!text) {
    return mode === 'seller'
      ? { kind: 'help', reply: 'What would you like help with?', suggestions: SELLER_SUGGESTIONS }
      : {
          kind: 'help',
          reply: 'What are you looking for today?',
          suggestions: ['Dresses for a party', 'Men formal shirts', 'Track my order', 'I have a complaint'],
        };
  }

  // Greetings are mode-aware.
  if (GREETING_RE.test(text)) {
    return mode === 'seller'
      ? {
          kind: 'small_talk',
          reply: "Hi! I can walk you through the seller flow — adding products, confirming orders, printing labels, settlements. What's on your mind?",
          suggestions: SELLER_SUGGESTIONS,
        }
      : {
          kind: 'small_talk',
          reply: "Hi! I can help you find products, check an order, or raise a complaint. What are you in the mood for?",
          suggestions: ['Looking for party wear', 'Formal shirts for office', 'Where is my order?'],
        };
  }

  // 1. Complaint flow trumps everything else for both modes.
  if (COMPLAINT_RE.test(text)) {
    return {
      kind: 'complaint',
      reply: "Sorry you're running into something. Tell me what happened — I'll log a ticket and the team will follow up. What's the issue about?",
      suggestions: ['Delivery', 'Product quality', 'Payment / refund', 'Account', 'Something else'],
    };
  }

  // 2. Seller-mode how-tos. These run BEFORE the buyer shortcuts so phrases
  //    like "track my order" don't accidentally pull a seller into /user/orders.
  if (mode === 'seller') {
    for (const h of SELLER_HOWTOS) if (h.match.test(text)) return h.build();
    // Fallback for sellers — friendly capability list rather than a buyer search.
    return {
      kind: 'help',
      reply: SELLER_HELP_REPLY,
      suggestions: SELLER_SUGGESTIONS,
    };
  }

  // 3. Buyer navigation shortcuts.
  if (ORDER_RE.test(text)) {
    return {
      kind: 'order_status',
      reply: 'Here are your recent orders.',
      href: '/user/orders',
      suggestions: ['Track a specific order', 'Cancel an order', 'Return policy'],
    };
  }
  if (WALLET_RE.test(text)) {
    return {
      kind: 'wallet',
      reply: 'Your wallet has the full credit + transaction history.',
      href: '/user/wallet',
    };
  }
  if (WISHLIST_RE.test(text)) {
    return { kind: 'wishlist', reply: 'Opening your wishlist.', href: '/user/wishlist' };
  }
  if (CART_RE.test(text)) {
    return { kind: 'cart', reply: 'Opening your cart.', href: '/user/cart' };
  }

  // 4. Product-search intent. Build a /home/products?... URL from the slots we can extract.
  const slots = extractProductSlots(text);
  if (slots.qParts.length > 0 || slots.gender || slots.tags.length > 0 || slots.maxPrice || slots.minPrice) {
    const params = new URLSearchParams();
    if (slots.qParts.length > 0)  params.set('search', slots.qParts.join(' '));
    if (slots.gender)             params.set('gender', String(slots.gender.id));
    if (slots.tags.length > 0)    params.set('tags',  slots.tags.join(','));
    if (slots.maxPrice)           params.set('maxPrice', String(slots.maxPrice));
    if (slots.minPrice)           params.set('minPrice', String(slots.minPrice));

    const labelBits = [
      slots.gender?.label,
      slots.categories.map(c => c.label).join(' & '),
      slots.tags.length > 0 ? slots.tags.join(' / ') : null,
      slots.maxPrice ? `under ₹${slots.maxPrice}` : null,
      slots.minPrice ? `above ₹${slots.minPrice}` : null,
    ].filter(Boolean);

    return {
      kind: 'navigate',
      reply: labelBits.length > 0
        ? `Got it — looking for ${labelBits.join(' · ')}. Want me to open the matches?`
        : 'I can search for that. Should I open the results?',
      href: `/home/products?${params.toString()}`,
      suggestions: slots.gender ? undefined : ['For men', 'For women', 'Under ₹2000'],
      meta: { searchQuery: slots.qParts.join(' ') },
    };
  }

  // 4. Fallback.
  return {
    kind: 'help',
    reply: "I didn't quite catch that. Try something like \"formal shirts for office\" or \"I have a complaint about my last order\".",
    suggestions: ['Birthday gift for her', 'Show me running shoes', 'Where is my order?', 'I want to file a complaint'],
  };
}

/** Pulls categories, gender, occasion tags and price slots out of a free-text query. */
function extractProductSlots(text: string) {
  const tags: string[] = [];
  const categories: { tag: string; label: string }[] = [];
  let gender: typeof GENDER_KEYWORDS[number] | undefined;
  let maxPrice: number | undefined;
  let minPrice: number | undefined;

  for (const c of CATEGORY_KEYWORDS) if (c.match.test(text)) categories.push({ tag: c.tag, label: c.label });
  for (const g of GENDER_KEYWORDS)   if (g.match.test(text)) { gender = g; break; }
  for (const o of OCCASION_TAGS)     if (o.match.test(text) && !tags.includes(o.tag)) tags.push(o.tag);

  for (const p of PRICE_PATTERNS) {
    const m = text.match(p.match);
    if (m) {
      const n = Number(m[1]);
      if (Number.isFinite(n)) {
        if (p.key === 'maxPrice') maxPrice = n;
        else                       minPrice = n;
      }
    }
  }

  // Build search-query parts from category labels + leftover nouns. Strip stopwords so the
  // resulting `search` param is reasonably tight.
  const qParts = categories.map(c => c.tag);
  return { qParts, tags, categories, gender, maxPrice, minPrice };
}
