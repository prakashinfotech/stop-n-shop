using System.Text;

namespace ShopNShop.Api.Common;

/// <summary>
/// Decodes the base64 wrapper the frontend applies to password fields before
/// they leave the browser, so a password never appears as a literal
/// human-readable string in the request payload (network panel, logging
/// proxies, a screen-share of devtools).
///
/// This is NOT encryption — base64 has no key, and anyone who sees the
/// encoded value can reverse it instantly with no secret. It only avoids a
/// plaintext password sitting in the open in transit logs/tooling; it does
/// not protect against TLS interception or a compromised client. Upgrade to
/// a keyed scheme (e.g. RSA-OAEP with a server-held private key) if a
/// stronger guarantee is ever required.
///
/// Call this at the very top of each controller action, before any existing
/// validation or hashing runs, so everything downstream (length checks,
/// HashPassword/VerifyPassword, stored procedures) keeps operating on the
/// real plaintext exactly as it did before — this only changes what crosses
/// the wire, not how it's handled once it arrives.
/// </summary>
public static class PasswordTransitCodec
{
    public static string Decode(string? encoded)
    {
        if (string.IsNullOrEmpty(encoded)) return string.Empty;

        try
        {
            var bytes = Convert.FromBase64String(encoded);
            return Encoding.UTF8.GetString(bytes);
        }
        catch (FormatException)
        {
            // Not valid base64 — assume an already-plaintext caller (Postman,
            // Swagger, direct API testing) and pass it through unchanged
            // rather than failing requests that predate this change.
            return encoded;
        }
    }
}
