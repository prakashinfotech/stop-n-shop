using System.Net;
using System.Net.Mail;

namespace ShopNShop.Api.Services;

public interface IEmailService
{
    Task SendForgotPasswordOtpAsync(string toEmail, string firstName, string otpCode);
    Task SendOrderConfirmationAsync(string toEmail, string toName, int orderId, string orderNumber, decimal totalAmount);
    Task SendOrderCancellationAsync(string toEmail, string toName, int orderId, string orderNumber, decimal totalAmount, bool walletRefunded);
    Task SendOrderStatusUpdateAsync(string toEmail, string toName, string orderNumber, string newStatus, string? estimatedDeliveryDate = null);
}

public class EmailService(IConfiguration config, ILogger<EmailService> logger) : IEmailService
{
    public async Task SendForgotPasswordOtpAsync(string toEmail, string firstName, string otpCode)
    {
        try
        {
            var host      = config["Smtp:Host"]      ?? "smtp.office365.com";
            var port      = int.Parse(config["Smtp:Port"] ?? "587");
            var user      = config["Smtp:User"]      ?? string.Empty;
            var password  = config["Smtp:Password"]  ?? string.Empty;
            var fromEmail = config["Smtp:FromEmail"] ?? user;
            var fromName  = config["Smtp:FromName"]  ?? "Stop-N-Shop";

            if (string.IsNullOrWhiteSpace(user) || string.IsNullOrWhiteSpace(fromEmail))
            {
                logger.LogWarning("SMTP not configured — skipping forgot-password OTP email to {Email}", toEmail);
                return;
            }

            var name = string.IsNullOrWhiteSpace(firstName) ? "there" : firstName;
            var body = BuildOtpEmailBody(name, otpCode);

            using var smtp = new SmtpClient(host, port)
            {
                Credentials = new NetworkCredential(user, password),
                EnableSsl   = true,
            };

            using var msg = new MailMessage
            {
                From       = new MailAddress(fromEmail, fromName),
                Subject    = $"Your Stop-N-Shop password reset code: {otpCode}",
                Body       = body,
                IsBodyHtml = true,
            };
            msg.To.Add(new MailAddress(toEmail, name));

            await smtp.SendMailAsync(msg);
            logger.LogInformation("Forgot-password OTP email sent to {Email}", toEmail);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to send forgot-password OTP email to {Email}", toEmail);
        }
    }

    public async Task SendOrderConfirmationAsync(
        string toEmail, string toName, int orderId, string orderNumber, decimal totalAmount)
    {
        try
        {
            var host     = config["Smtp:Host"]      ?? "smtp.office365.com";
            var port     = int.Parse(config["Smtp:Port"] ?? "587");
            var user     = config["Smtp:User"]      ?? string.Empty;
            var password = config["Smtp:Password"]  ?? string.Empty;
            var fromEmail = config["Smtp:FromEmail"] ?? user;
            var fromName  = config["Smtp:FromName"]  ?? "Stop-N-Shop";

            // In test mode, send to fallback ToEmail if buyer email is empty
            var recipient = string.IsNullOrWhiteSpace(toEmail)
                ? (config["Smtp:ToEmail"] ?? user)
                : toEmail;

            var body = BuildHtmlBody(toName, orderId, orderNumber, totalAmount);

            using var smtp = new SmtpClient(host, port)
            {
                Credentials = new NetworkCredential(user, password),
                EnableSsl   = true,
            };

            using var msg = new MailMessage
            {
                From       = new MailAddress(fromEmail, fromName),
                Subject    = $"Order Confirmed! #{orderNumber} — Stop-N-Shop",
                Body       = body,
                IsBodyHtml = true,
            };
            msg.To.Add(new MailAddress(recipient, toName));

            await smtp.SendMailAsync(msg);
            logger.LogInformation("Order confirmation email sent to {Email} for order {OrderNumber}", recipient, orderNumber);
        }
        catch (Exception ex)
        {
            // Never let email failure break the order flow
            logger.LogError(ex, "Failed to send order confirmation email for order {OrderNumber}", orderNumber);
        }
    }

    public async Task SendOrderCancellationAsync(
        string toEmail, string toName, int orderId, string orderNumber, decimal totalAmount, bool walletRefunded)
    {
        // Note: walletRefunded=true ⇒ prepaid order, refund credited to wallet.
        // walletRefunded=false ⇒ Cash on Delivery, no refund needed.
        try
        {
            var host      = config["Smtp:Host"]      ?? "smtp.office365.com";
            var port      = int.Parse(config["Smtp:Port"] ?? "587");
            var user      = config["Smtp:User"]      ?? string.Empty;
            var password  = config["Smtp:Password"]  ?? string.Empty;
            var fromEmail = config["Smtp:FromEmail"] ?? user;
            var fromName  = config["Smtp:FromName"]  ?? "Stop-N-Shop";

            var recipient = string.IsNullOrWhiteSpace(toEmail)
                ? (config["Smtp:ToEmail"] ?? user)
                : toEmail;

            var body = BuildCancellationHtmlBody(toName, orderId, orderNumber, totalAmount, walletRefunded);

            using var smtp = new SmtpClient(host, port)
            {
                Credentials = new NetworkCredential(user, password),
                EnableSsl   = true,
            };

            using var msg = new MailMessage
            {
                From       = new MailAddress(fromEmail, fromName),
                Subject    = $"Order Cancelled — #{orderNumber} | Stop-N-Shop",
                Body       = body,
                IsBodyHtml = true,
            };
            msg.To.Add(new MailAddress(recipient, toName));

            await smtp.SendMailAsync(msg);
            logger.LogInformation("Order cancellation email sent to {Email} for order {OrderNumber}", recipient, orderNumber);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to send order cancellation email for order {OrderNumber}", orderNumber);
        }
    }

    private static string BuildOtpEmailBody(string name, string otpCode)
    {
        // The OTP itself is rendered via a custom section (large, monospace, dashed border)
        // rather than the standard details table.
        var otpBlock = $"""
          <tr>
            <td style="padding:24px 40px 8px;text-align:center;">
              <div style="display:inline-block;background:#faf6ec;border:2px dashed #c41230;border-radius:16px;padding:18px 40px;">
                <p style="margin:0;font-size:10px;font-weight:700;color:#a01028;text-transform:uppercase;letter-spacing:0.18em;">Your verification code</p>
                <p style="margin:8px 0 0;font-family:'Courier New',monospace;font-size:38px;font-weight:900;letter-spacing:0.3em;color:#1c1917;">{otpCode}</p>
              </div>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 40px 24px;text-align:center;">
              <p style="margin:0;font-size:12px;color:#a8a29e;">
                If you didn't request this, you can safely ignore the email — your account stays secure.
              </p>
            </td>
          </tr>
          """;

        return EmailLayout(
            title: "Password Reset",
            preheader: $"Your Stop-N-Shop verification code is {otpCode}. Expires in 10 minutes.",
            heroBg: "#faf6ec",
            heroBorder: "#f0eae0",
            heroIconBg: BrandRed,
            heroIconGlyph: "🔑",
            heroHeading: $"Hi {name}, here's your reset code",
            heroSubcopy: "Use the code below to reset your password. Valid for the next 10 minutes.",
            heroSubcopyColor: MuteColor,
            sectionsHtml: otpBlock,
            footerNote: "For your security, never share this code with anyone — not even Stop-N-Shop staff."
        );
    }

    private static string BuildCancellationHtmlBody(string name, int orderId, string orderNumber, decimal totalAmount, bool walletRefunded)
    {
        var ordersUrl = $"http://localhost:3000/user/orders/{orderId}";
        var walletUrl = $"http://localhost:3000/user/wallet";

        // Refund copy is required-by-product:
        //   COD            → "Payment mode: COD, no refund pending."
        //   Pre-paid (any) → "Refund will be initiated. Please check wallet."
        var refundLine = walletRefunded
            ? "Refund will be initiated. Please check wallet."
            : "Payment mode: COD, no refund pending.";

        var refundChipRow = walletRefunded
            ? Row("Refund", Chip("Credited to Wallet", "#ecfdf5", "#047857"))
            : Row("Payment Mode", Chip("Cash on Delivery", "#fef3c7", "#92400e"));

        var detailsTable = DetailsTable(new (string, string)[]
        {
            ("Order ID", $"<span style=\"font-weight:700;color:{InkColor};\">#{orderNumber}</span>"),
            ("Amount",   $"<span style=\"font-size:18px;font-weight:800;color:{InkColor};\">₹{totalAmount:N2}</span>"),
            ("Status",   Chip("CANCELLED", "#fef2f2", BrandRed)),
        }.Concat(new[] { refundChipRow }).ToArray());

        var ctaBlock = Cta(ordersUrl, "View Order Details");
        if (walletRefunded)
            ctaBlock += SecondaryCta(walletUrl, "Open My Wallet →");

        return EmailLayout(
            title: "Order Cancelled",
            preheader: $"Order #{orderNumber} has been cancelled. {refundLine}",
            heroBg: "#fef2f2",
            heroBorder: "#fecaca",
            heroIconBg: BrandRed,
            heroIconGlyph: "✕",
            heroHeading: $"Order cancelled, {name}",
            heroSubcopy: refundLine,
            heroSubcopyColor: "#7f1d1d",
            sectionsHtml: detailsTable + ctaBlock,
            footerNote: "We're sorry this order didn't work out. Reply to this email if you need help."
        );
    }

    public async Task SendOrderStatusUpdateAsync(string toEmail, string toName, string orderNumber, string newStatus, string? estimatedDeliveryDate = null)
    {
        try
        {
            var host      = config["Smtp:Host"]      ?? "smtp.office365.com";
            var port      = int.Parse(config["Smtp:Port"] ?? "587");
            var user      = config["Smtp:User"]      ?? string.Empty;
            var password  = config["Smtp:Password"]  ?? string.Empty;
            var fromEmail = config["Smtp:FromEmail"] ?? user;
            var fromName  = config["Smtp:FromName"]  ?? "Stop-N-Shop";

            var recipient = string.IsNullOrWhiteSpace(toEmail)
                ? (config["Smtp:ToEmail"] ?? user)
                : toEmail;

            var name = string.IsNullOrWhiteSpace(toName) ? "Valued Customer" : toName;
            var body = BuildStatusUpdateHtmlBody(name, orderNumber, newStatus, estimatedDeliveryDate);

            using var smtp = new SmtpClient(host, port)
            {
                Credentials = new NetworkCredential(user, password),
                EnableSsl   = true,
            };

            using var msg = new MailMessage
            {
                From       = new MailAddress(fromEmail, fromName),
                Subject    = $"Order #{orderNumber} — {GetStatusLabel(newStatus)} | Stop-N-Shop",
                Body       = body,
                IsBodyHtml = true,
            };
            msg.To.Add(new MailAddress(recipient, name));

            await smtp.SendMailAsync(msg);
            logger.LogInformation("Order status update email sent to {Email} for order {OrderNumber}", recipient, orderNumber);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Failed to send order status update email for order {OrderNumber}", orderNumber);
        }
    }

    private static string BuildHtmlBody(string name, int orderId, string orderNumber, decimal totalAmount)
    {
        var trackUrl = $"http://localhost:3000/user/orders/{orderId}";

        var details = DetailsTable(new (string, string)[]
        {
            ("Order ID",      $"<span style=\"font-weight:700;color:{InkColor};\">#{orderNumber}</span>"),
            ("Total Amount",  $"<span style=\"font-size:18px;font-weight:800;color:{InkColor};\">₹{totalAmount:N2}</span>"),
            ("Status",        Chip("PLACED", "#eff6ff", "#1d4ed8")),
        });

        return EmailLayout(
            title: "Order Confirmed",
            preheader: $"Your order #{orderNumber} of ₹{totalAmount:N2} has been placed.",
            heroBg: "#ecfdf5",
            heroBorder: "#d1fae5",
            heroIconBg: "#10b981",
            heroIconGlyph: "✓",
            heroHeading: $"Thank you, {name}",
            heroSubcopy: "Your order has been placed successfully. We'll notify you once it ships.",
            heroSubcopyColor: "#047857",
            sectionsHtml: details + Cta(trackUrl, "Track My Order") + TrackingHint(),
            footerNote: $"Thank you for shopping with Stop-N-Shop."
        );
    }

    private static string TrackingHint() => $"""
      <tr><td style="padding:0 40px 28px;text-align:center;">
        <p style="margin:0;font-size:13px;color:#6b7280;">
          You can also track your order any time from the <strong style="color:{InkColor};">My Orders</strong> section.
        </p>
      </td></tr>
      """;

    private static string BuildStatusUpdateHtmlBody(string name, string orderNumber, string newStatus, string? estimatedDeliveryDate)
    {
        var statusLabel = GetStatusLabel(newStatus);
        var statusGlyph = newStatus switch
        {
            "2" or "Confirmed"  => "✓",
            "3" or "Processing" => "▢",
            "4" or "Shipped"    => "➤",
            "5" or "Delivered"  => "✓",
            _                   => "•",
        };
        var statusColor = newStatus switch
        {
            "2" or "Confirmed"  => "#047857",
            "3" or "Processing" => "#b45309",
            "4" or "Shipped"    => "#1d4ed8",
            "5" or "Delivered"  => "#047857",
            _                   => "#6b7280",
        };

        var rows = new List<(string, string)>
        {
            ("Order ID", $"<span style=\"font-weight:700;color:{InkColor};\">#{orderNumber}</span>"),
            ("Status",   Chip(statusLabel.ToUpper(), "#f0fdf4", statusColor)),
        };
        if (!string.IsNullOrWhiteSpace(estimatedDeliveryDate))
            rows.Add(("Expected Delivery", $"<span style=\"font-weight:700;color:{InkColor};\">{estimatedDeliveryDate}</span>"));

        return EmailLayout(
            title: $"Order {statusLabel}",
            preheader: $"Order #{orderNumber} has been {statusLabel.ToLower()}.",
            heroBg: "#f0fdf4",
            heroBorder: "#d1fae5",
            heroIconBg: statusColor,
            heroIconGlyph: statusGlyph,
            heroHeading: $"Order {statusLabel.ToLower()}, {name}",
            heroSubcopy: $"Order #{orderNumber} has been {statusLabel.ToLower()}.",
            heroSubcopyColor: statusColor,
            sectionsHtml: DetailsTable(rows.ToArray()) + Cta($"http://localhost:3000/user/orders", "View My Orders"),
            footerNote: "Thank you for shopping with Stop-N-Shop."
        );
    }

    private static string GetStatusLabel(string status) => status switch
    {
        "1" or "Pending"    => "Pending",
        "2" or "Confirmed"  => "Confirmed",
        "3" or "Processing" => "Processing",
        "4" or "Shipped"    => "Shipped",
        "5" or "Delivered"  => "Delivered",
        "6" or "Cancelled"  => "Cancelled",
        _                   => status,
    };

    // ── Shared email layout helpers ───────────────────────────────────────
    // Brand palette mirrors stopnshop-ui/docs/DESIGN_SYSTEM.md: warm cream surfaces
    // (#fdfbf6) + Shoppers-Stop red (#c41230) for headers/CTAs.
    private const string BrandRed  = "#c41230";
    private const string BrandRed2 = "#a01028";  // darker tone for header gradient stop
    private const string InkColor  = "#1c1917";  // stone-900
    private const string MuteColor = "#78716c";  // stone-500
    private const string PageBg    = "#fdfbf6";

    /// <summary>Wraps every transactional email in a single bullet-proof, table-based layout.</summary>
    private static string EmailLayout(
        string title, string preheader,
        string heroBg, string heroBorder, string heroIconBg, string heroIconGlyph,
        string heroHeading, string heroSubcopy, string heroSubcopyColor,
        string sectionsHtml, string footerNote)
    {
        // Preheader = hidden inbox snippet shown next to the subject line.
        return $"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1.0" />
          <title>{title}</title>
        </head>
        <body style="margin:0;padding:0;background:{PageBg};font-family:'Helvetica Neue','Segoe UI',Arial,sans-serif;color:{InkColor};">
          <span style="display:none!important;visibility:hidden;opacity:0;color:transparent;height:0;width:0;overflow:hidden;mso-hide:all;">{preheader}</span>
          <table width="100%" cellpadding="0" cellspacing="0" style="background:{PageBg};padding:40px 16px;">
            <tr><td align="center">
              <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border:1px solid #f0eae0;border-radius:20px;overflow:hidden;box-shadow:0 6px 24px rgba(28,25,23,0.06);">

                <!-- Brand header -->
                <tr>
                  <td style="background:linear-gradient(135deg,{BrandRed} 0%,{BrandRed2} 100%);padding:28px 40px;text-align:center;">
                    <p style="margin:0;color:#ffffff;font-family:'Georgia','Times New Roman',serif;font-size:26px;font-weight:700;letter-spacing:-0.5px;line-height:1;">
                      Stop<span style="color:#fbbf24;font-style:italic;">N</span>Shop
                    </p>
                    <p style="margin:6px 0 0;color:#fde7eb;font-size:11px;letter-spacing:0.16em;text-transform:uppercase;">India's Premium Fashion Destination</p>
                  </td>
                </tr>

                <!-- Hero banner -->
                <tr>
                  <td style="background:{heroBg};border-bottom:1px solid {heroBorder};padding:32px 40px;text-align:center;">
                    <div style="width:56px;height:56px;background:{heroIconBg};border-radius:50%;display:inline-block;text-align:center;margin-bottom:14px;line-height:56px;">
                      <span style="color:#fff;font-size:26px;line-height:56px;vertical-align:middle;">{heroIconGlyph}</span>
                    </div>
                    <h2 style="margin:0 0 6px;color:{InkColor};font-family:'Georgia','Times New Roman',serif;font-size:22px;font-weight:700;letter-spacing:-0.2px;">
                      {heroHeading}
                    </h2>
                    <p style="margin:0;color:{heroSubcopyColor};font-size:14px;line-height:1.55;">
                      {heroSubcopy}
                    </p>
                  </td>
                </tr>

                <!-- Sections (details table + CTA + any extra rows) -->
                {sectionsHtml}

                <!-- Divider -->
                <tr><td style="padding:0 40px;"><hr style="border:none;border-top:1px solid #f0eae0;margin:0;" /></td></tr>

                <!-- Footer -->
                <tr>
                  <td style="padding:20px 40px 28px;text-align:center;">
                    <p style="margin:0 0 6px;font-size:12px;color:{MuteColor};line-height:1.55;">{footerNote}</p>
                    <p style="margin:10px 0 0;font-size:11px;color:#a8a29e;">
                      Need help? Reply to this email or visit our <a href="http://localhost:3000/help" style="color:{BrandRed};text-decoration:none;font-weight:600;">help centre</a>.
                    </p>
                    <p style="margin:14px 0 0;font-size:10px;color:#d6d3d1;letter-spacing:0.06em;">© 2026 Stop-N-Shop · All rights reserved</p>
                  </td>
                </tr>

              </table>
            </td></tr>
          </table>
        </body>
        </html>
        """;
    }

    /// <summary>Renders the cream details panel with label → value rows.</summary>
    private static string DetailsTable((string Label, string ValueHtml)[] rows)
    {
        var rowHtml = string.Concat(rows.Select((r, i) =>
            $"""
            <tr>
              <td style="padding:14px 20px;font-size:13px;color:{MuteColor};{(i == 0 ? "" : "border-top:1px solid #f0eae0;")}">{r.Label}</td>
              <td style="padding:14px 20px;text-align:right;{(i == 0 ? "" : "border-top:1px solid #f0eae0;")}">{r.ValueHtml}</td>
            </tr>
            """));

        return $"""
        <tr>
          <td style="padding:28px 40px 20px;">
            <table width="100%" cellpadding="0" cellspacing="0" style="background:{PageBg};border:1px solid #f0eae0;border-radius:14px;overflow:hidden;">
              <tr>
                <td colspan="2" style="padding:12px 20px;background:#faf6ec;font-size:11px;font-weight:700;color:{MuteColor};text-transform:uppercase;letter-spacing:0.1em;">
                  Order Details
                </td>
              </tr>
              {rowHtml}
            </table>
          </td>
        </tr>
        """;
    }

    private static (string Label, string ValueHtml) Row(string label, string valueHtml) => (label, valueHtml);

    private static string Chip(string text, string bg, string fg) =>
        $"<span style=\"display:inline-block;background:{bg};color:{fg};font-size:11px;font-weight:700;padding:4px 10px;border-radius:99px;letter-spacing:0.04em;\">{text}</span>";

    /// <summary>Primary action button.</summary>
    private static string Cta(string url, string label) => $"""
      <tr>
        <td style="padding:8px 40px 28px;text-align:center;">
          <a href="{url}" style="display:inline-block;background:{BrandRed};color:#ffffff;font-size:14px;font-weight:700;padding:13px 32px;border-radius:999px;text-decoration:none;letter-spacing:0.02em;box-shadow:0 4px 12px rgba(196,18,48,0.25);">
            {label}
          </a>
        </td>
      </tr>
      """;

    /// <summary>Secondary outline button shown below the primary CTA.</summary>
    private static string SecondaryCta(string url, string label) => $"""
      <tr>
        <td style="padding:0 40px 28px;text-align:center;">
          <a href="{url}" style="display:inline-block;background:#ffffff;color:{InkColor};font-size:13px;font-weight:600;padding:11px 26px;border-radius:999px;text-decoration:none;border:1px solid #e7e5e4;">
            {label}
          </a>
        </td>
      </tr>
      """;
}
