export type AIIntent =
  | 'search_products'
  | 'track_order'
  | 'product_recommendation'
  | 'loyalty_points'
  | 'return_request'
  | 'wallet_balance'
  | 'seller_inventory'
  | 'admin_insights';

export interface AIMessage {
  id: string;
  content: string;
  sender: 'user' | 'aria';
  timestamp: Date;
  intent?: AIIntent;
}

export interface AIResponse {
  message: string;
  intent: AIIntent;
  actionUrl?: string;
  data?: Record<string, unknown>;
}

const intentResponses: Record<AIIntent, (context?: Record<string, unknown>) => AIResponse> = {
  search_products: (context) => ({
    message: `I found products matching "${context?.query || 'your search'}". Would you like to see them sorted by price, rating, or newest?`,
    intent: 'search_products',
    actionUrl: `/search?q=${context?.query || ''}`,
    data: { productCount: Math.floor(Math.random() * 50) + 10 },
  }),

  track_order: () => ({
    message: 'Your order is on its way! 📦 It will be delivered by tomorrow. Current status: Out for delivery. View details below.',
    intent: 'track_order',
    actionUrl: '/orders',
    data: { orderId: Math.floor(Math.random() * 10000), status: 'out_for_delivery' },
  }),

  product_recommendation: () => ({
    message: 'Based on your browsing history, I think you\'ll love these items! ✨ They match your style and are trending right now.',
    intent: 'product_recommendation',
    actionUrl: '/trending',
    data: { productCount: 5, category: 'fashion' },
  }),

  loyalty_points: () => ({
    message: 'You have 2,450 loyalty points available! 🎉 You\'re 550 points away from the next tier. Want to see rewards?',
    intent: 'loyalty_points',
    actionUrl: '/loyalty',
    data: { points: 2450, nextTier: 3000 },
  }),

  return_request: (context) => ({
    message: `I can help with your return for order #${context?.orderId || '12345'}. Is there an issue with one item or the entire order?`,
    intent: 'return_request',
    actionUrl: '/returns',
    data: { orderId: context?.orderId },
  }),

  wallet_balance: () => ({
    message: 'Your wallet balance is ₹1,250. You can use this for your next purchase. Would you like to add more funds?',
    intent: 'wallet_balance',
    actionUrl: '/wallet',
    data: { balance: 1250 },
  }),

  seller_inventory: () => ({
    message: 'Your inventory looks great! 📊 You have 485 products listed and 12 are low on stock. Check details?',
    intent: 'seller_inventory',
    actionUrl: '/seller/inventory',
    data: { totalProducts: 485, lowStock: 12 },
  }),

  admin_insights: () => ({
    message: 'Daily metrics show a 15% increase in orders and strong customer engagement. See full analytics dashboard?',
    intent: 'admin_insights',
    actionUrl: '/admin/analytics',
    data: { orderIncrease: 15, engagement: 'strong' },
  }),
};

export const parseUserInput = (input: string): AIIntent => {
  const lowerInput = input.toLowerCase();

  if (lowerInput.includes('search') || lowerInput.includes('find') || lowerInput.includes('looking for')) {
    return 'search_products';
  }
  if (lowerInput.includes('track') || lowerInput.includes('order') || lowerInput.includes('where is')) {
    return 'track_order';
  }
  if (lowerInput.includes('recommend') || lowerInput.includes('suggest') || lowerInput.includes('similar')) {
    return 'product_recommendation';
  }
  if (lowerInput.includes('points') || lowerInput.includes('loyalty') || lowerInput.includes('reward')) {
    return 'loyalty_points';
  }
  if (lowerInput.includes('return') || lowerInput.includes('exchange') || lowerInput.includes('refund')) {
    return 'return_request';
  }
  if (lowerInput.includes('wallet') || lowerInput.includes('balance') || lowerInput.includes('payment')) {
    return 'wallet_balance';
  }
  if (lowerInput.includes('inventory') || lowerInput.includes('stock') || lowerInput.includes('seller')) {
    return 'seller_inventory';
  }
  if (lowerInput.includes('analytics') || lowerInput.includes('dashboard') || lowerInput.includes('insights')) {
    return 'admin_insights';
  }

  return 'search_products';
};

export const generateAIResponse = (intent: AIIntent, context?: Record<string, unknown>): AIResponse => {
  return intentResponses[intent](context);
};

export const extractEntities = (input: string): Record<string, unknown> => {
  const context: Record<string, unknown> = {};

  const queryMatch = input.match(/(?:search|find|looking for)\s+(.+?)(?:\?|$)/i);
  if (queryMatch) context.query = queryMatch[1];

  const orderMatch = input.match(/(?:order|order id)[\s#]*(\d+)/i);
  if (orderMatch) context.orderId = orderMatch[1];

  return context;
};
