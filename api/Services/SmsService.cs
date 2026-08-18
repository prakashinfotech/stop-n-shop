using Twilio;
using Twilio.Rest.Api.V2010.Account;
using Twilio.Types;

namespace ShopNShop.Api.Services;

public interface ISmsService
{
    /// <summary>Sends an SMS. Returns true if dispatched to Twilio, false if
    /// skipped (provider not configured) or failed. Never throws — SMS is a
    /// best-effort side channel and must not break the calling flow.</summary>
    Task<bool> SendAsync(string toMobile, string message);
}

/// <summary>
/// Twilio-backed SMS sender with graceful degradation. If AccountSid / AuthToken
/// / FromNumber aren't configured (e.g. local dev, or before a trial number is
/// provisioned) it logs and returns false instead of throwing — the OTP still
/// reaches the buyer via the in-app Notification written by the SP.
///
/// Config comes from Twilio:AccountSid / Twilio:AuthToken / Twilio:FromNumber,
/// which Docker injects from the gitignored .env via Twilio__* env vars.
/// </summary>
public class SmsService(IConfiguration config, ILogger<SmsService> logger) : ISmsService
{
    public Task<bool> SendAsync(string toMobile, string message)
    {
        var sid   = config["Twilio:AccountSid"];
        var token = config["Twilio:AuthToken"];
        var from  = config["Twilio:FromNumber"];

        if (string.IsNullOrWhiteSpace(sid) || string.IsNullOrWhiteSpace(token) || string.IsNullOrWhiteSpace(from))
        {
            logger.LogWarning("Twilio not configured (missing SID/token/from) — SMS to {To} skipped. " +
                              "Buyer still gets the in-app notification.", Mask(toMobile));
            return Task.FromResult(false);
        }

        if (string.IsNullOrWhiteSpace(toMobile))
        {
            logger.LogWarning("SMS skipped — recipient has no mobile on file.");
            return Task.FromResult(false);
        }

        try
        {
            TwilioClient.Init(sid, token);
            var result = MessageResource.Create(
                to:   new PhoneNumber(ToE164(toMobile)),
                from: new PhoneNumber(from),
                body: message);

            logger.LogInformation("SMS queued to {To} (Twilio SID {Sid}, status {Status}).",
                Mask(toMobile), result.Sid, result.Status);
            return Task.FromResult(true);
        }
        catch (Exception ex)
        {
            // Trial accounts reject unverified recipients; international/DLT routing
            // can also fail. Swallow — the in-app OTP already covers the buyer.
            logger.LogWarning(ex, "Twilio SMS to {To} failed — buyer still has the in-app OTP.", Mask(toMobile));
            return Task.FromResult(false);
        }
    }

    // Normalises a bare 10-digit Indian mobile to E.164 (+91…). Leaves already-
    // prefixed numbers untouched.
    private static string ToE164(string raw)
    {
        var digits = new string(raw.Where(char.IsDigit).ToArray());
        if (raw.TrimStart().StartsWith('+')) return raw.Trim();
        if (digits.Length == 10) return "+91" + digits;          // Indian mobile
        if (digits.Length == 12 && digits.StartsWith("91")) return "+" + digits;
        return "+" + digits;
    }

    private static string Mask(string? mobile)
    {
        if (string.IsNullOrEmpty(mobile) || mobile.Length < 4) return "****";
        return new string('*', Math.Max(0, mobile.Length - 4)) + mobile[^4..];
    }
}
