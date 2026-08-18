/**
 * Tiny JWT helper — no signature verification (that's the API's job).
 * We only need to read the `exp` claim client-side to decide whether to
 * trust a cached token, so we don't pull in jose/jsonwebtoken.
 */

interface JwtPayload {
  exp?: number;
  [key: string]: unknown;
}

export function decodeJwt(token: string): JwtPayload | null {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = payload + '='.repeat((4 - (payload.length % 4)) % 4);
    return JSON.parse(atob(padded)) as JwtPayload;
  } catch {
    return null;
  }
}

/**
 * Returns true when the token's exp claim is in the past (with a small clock-skew
 * tolerance) OR the token is structurally invalid. Returning true for invalid tokens
 * is intentional — a malformed cached token is effectively expired.
 */
export function isJwtExpired(token: string, clockSkewSeconds = 5): boolean {
  const claims = decodeJwt(token);
  if (!claims?.exp) return true;
  const nowSeconds = Math.floor(Date.now() / 1000);
  return claims.exp - clockSkewSeconds <= nowSeconds;
}
