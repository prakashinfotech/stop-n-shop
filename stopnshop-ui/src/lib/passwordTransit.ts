/**
 * Base64-encodes a password before it leaves the browser, so it never appears
 * as a literal human-readable string in the request payload (network panel,
 * logging proxies, a screen-share of devtools).
 *
 * This is NOT encryption — base64 has no key, and anyone who sees the encoded
 * value can reverse it in one line with no secret. It only avoids a plaintext
 * password sitting in the open in transit logs/tooling; it does not protect
 * against TLS interception or a compromised client. Upgrade to a keyed scheme
 * (e.g. RSA-OAEP with a server-held private key) if a stronger guarantee is
 * ever required.
 *
 * The backend's matching decode step (PasswordTransitCodec.Decode) sits at the
 * very top of each controller action, before any existing validation/hashing
 * runs — so every endpoint's behavior is otherwise unchanged.
 */
export function encodePasswordForTransit(password: string): string {
  const bytes = new TextEncoder().encode(password);
  let binary = '';
  bytes.forEach((b) => {
    binary += String.fromCharCode(b);
  });
  return btoa(binary);
}
