using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;

namespace ShopNShop.Api.Controllers;

/// <summary>Razorpay — creates a Razorpay order that the frontend uses to open the payment modal.</summary>
[ApiController]
[Route("api/payments/razorpay")]
[Authorize]
[Produces("application/json")]
public class RazorpayController(IHttpClientFactory httpClientFactory, IConfiguration config) : ControllerBase
{
    /// <summary>
    /// Creates a Razorpay order for the given amount and returns the order ID and key needed
    /// by the frontend checkout.js SDK.
    /// </summary>
    /// <param name="req">Amount in INR (rupees).</param>
    [HttpPost("create-order")]
    [ProducesResponseType(typeof(ApiResponse<RazorpayOrderResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateOrder([FromBody] RazorpayCreateOrderRequest req)
    {
        var keyId     = config["Razorpay:KeyId"];
        var keySecret = config["Razorpay:KeySecret"];

        // Fail fast with a useful error instead of sending empty Basic-auth credentials
        // and getting a confusing 401 from upstream.
        if (string.IsNullOrWhiteSpace(keyId) || string.IsNullOrWhiteSpace(keySecret))
        {
            return BadRequest(ApiResponse<object>.Fail(
                "Razorpay is not configured on the server. Set Razorpay:KeyId and Razorpay:KeySecret in appsettings."));
        }

        var client = httpClientFactory.CreateClient();
        var credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes($"{keyId}:{keySecret}"));
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", credentials);

        // Razorpay expects amount in paise (smallest currency unit)
        var body = JsonSerializer.Serialize(new
        {
            amount   = (long)Math.Round(req.Amount * 100),
            currency = "INR",
            receipt  = $"rcpt_{Guid.NewGuid():N}"
        });

        var response = await client.PostAsync(
            "https://api.razorpay.com/v1/orders",
            new StringContent(body, Encoding.UTF8, "application/json"));

        if (!response.IsSuccessStatusCode)
            return BadRequest(ApiResponse<object>.Fail("Could not create Razorpay order. Please try again."));

        var json = await response.Content.ReadAsStringAsync();
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;

        return Ok(ApiResponse<RazorpayOrderResponse>.Ok(new RazorpayOrderResponse
        {
            OrderId  = root.GetProperty("id").GetString()!,
            Amount   = root.GetProperty("amount").GetInt64(),
            Currency = root.GetProperty("currency").GetString()!,
            KeyId    = keyId
        }));
    }
}

public class RazorpayCreateOrderRequest
{
    public decimal Amount { get; set; }
}

public class RazorpayOrderResponse
{
    public string OrderId  { get; set; } = string.Empty;
    public long   Amount   { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string KeyId    { get; set; } = string.Empty;
}
