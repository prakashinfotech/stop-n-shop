/**
 * Static size chart data, keyed by chart kind.
 * Frontend-only — admin-edited charts would live in a DB table later.
 *
 * Pick a kind from a product's category/subcategory via {@link resolveChartKind}.
 */

export type SizeChartKind = 'apparel-men' | 'apparel-women' | 'kids' | 'home-bedding' | null;

export interface SizeRow {
  label: string;
  /** Free-form measurement map — keys appear as table headers. */
  measurements: Record<string, string | number>;
}

export interface SizeChart {
  kind: SizeChartKind;
  title: string;
  /** Column headers in display order (excluding the size label column). */
  columns: string[];
  /** Unit suffix to append to numeric cells, e.g. "in", "cm", "₹". */
  unit?: string;
  rows: SizeRow[];
  note?: string;
}

const APPAREL_MEN: SizeChart = {
  kind: 'apparel-men',
  title: 'Men\'s Apparel Size Chart',
  columns: ['Chest', 'Waist', 'Front Length', 'Shoulder'],
  unit: 'in',
  rows: [
    { label: 'S',  measurements: { Chest: 38, Waist: 32, 'Front Length': 27, Shoulder: 17 } },
    { label: 'M',  measurements: { Chest: 40, Waist: 34, 'Front Length': 28, Shoulder: 18 } },
    { label: 'L',  measurements: { Chest: 42, Waist: 36, 'Front Length': 29, Shoulder: 18.5 } },
    { label: 'XL', measurements: { Chest: 44, Waist: 38, 'Front Length': 30, Shoulder: 19 } },
  ],
  note: 'Measurements are body measurements. Garment fit may vary by style.',
};

const APPAREL_WOMEN: SizeChart = {
  kind: 'apparel-women',
  title: 'Women\'s Apparel Size Chart',
  columns: ['Bust', 'Waist', 'Hip', 'Length'],
  unit: 'in',
  rows: [
    { label: 'XS', measurements: { Bust: 32, Waist: 25, Hip: 35, Length: 36 } },
    { label: 'S',  measurements: { Bust: 34, Waist: 27, Hip: 37, Length: 37 } },
    { label: 'M',  measurements: { Bust: 36, Waist: 29, Hip: 39, Length: 38 } },
    { label: 'L',  measurements: { Bust: 38, Waist: 31, Hip: 41, Length: 39 } },
    { label: 'XL', measurements: { Bust: 40, Waist: 33, Hip: 43, Length: 40 } },
  ],
  note: 'Measurements are body measurements. Garment fit may vary by style.',
};

const KIDS: SizeChart = {
  kind: 'kids',
  title: 'Kids Size Chart',
  columns: ['Age', 'Chest', 'Waist', 'Height'],
  unit: 'in',
  rows: [
    { label: '2-3Y', measurements: { Age: '2-3 years', Chest: 22, Waist: 21, Height: 38 } },
    { label: '4-5Y', measurements: { Age: '4-5 years', Chest: 24, Waist: 22, Height: 43 } },
    { label: '6-7Y', measurements: { Age: '6-7 years', Chest: 26, Waist: 23, Height: 48 } },
    { label: '8-9Y', measurements: { Age: '8-9 years', Chest: 28, Waist: 25, Height: 52 } },
  ],
};

const HOME_BEDDING: SizeChart = {
  kind: 'home-bedding',
  title: 'Bedding Size Chart',
  columns: ['Sheet', 'Bed Type'],
  unit: 'in',
  rows: [
    { label: 'Single', measurements: { Sheet: '60 x 90',  'Bed Type': 'Single Bed (36 x 75)' } },
    { label: 'Queen',  measurements: { Sheet: '90 x 100', 'Bed Type': 'Queen Bed (60 x 75)' } },
    { label: 'King',   measurements: { Sheet: '108 x 108','Bed Type': 'King Bed (72 x 75)' } },
  ],
};

const ALL: Record<Exclude<SizeChartKind, null>, SizeChart> = {
  'apparel-men':   APPAREL_MEN,
  'apparel-women': APPAREL_WOMEN,
  'kids':          KIDS,
  'home-bedding':  HOME_BEDDING,
};

/**
 * Resolve a chart kind from a product context. Falls back to null when no chart applies
 * (accessories, toys, etc.). Inputs are lowercased for forgiving matching.
 */
export function resolveChartKind(args: {
  menuName?: string | null;
  categoryName?: string | null;
  subCategoryName?: string | null;
}): SizeChartKind {
  const sub  = (args.subCategoryName ?? '').toLowerCase();
  const cat  = (args.categoryName ?? '').toLowerCase();
  const menu = (args.menuName ?? '').toLowerCase();

  if (sub.includes('bedding') || sub.includes('bedsheet') || cat.includes('bedding')) return 'home-bedding';
  if (menu === 'kids' || cat.includes('kids')) return 'kids';
  if (menu === 'women' || cat.includes('women')) return 'apparel-women';
  if (menu === 'men' || cat.includes('men') || cat.includes('clothing') || sub.includes('shirt') || sub.includes('t-shirt')) {
    return 'apparel-men';
  }
  return null;
}

export function getSizeChart(kind: Exclude<SizeChartKind, null>): SizeChart {
  return ALL[kind];
}
