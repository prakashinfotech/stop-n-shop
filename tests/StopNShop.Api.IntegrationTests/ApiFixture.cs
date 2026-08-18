using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Xunit;

namespace StopNShop.Api.IntegrationTests;

public sealed class ApiFixture : IAsyncLifetime
{
    public string BaseUrl { get; }
    public bool ApiReachable { get; private set; }
    public HttpClient Anonymous { get; }
    public HttpClient Buyer { get; private set; } = default!;
    public HttpClient Seller { get; private set; } = default!;
    public HttpClient Admin { get; private set; } = default!;

    public string? BuyerToken { get; private set; }
    public string? SellerToken { get; private set; }
    public string? AdminToken { get; private set; }

    public ApiFixture()
    {
        BaseUrl = Environment.GetEnvironmentVariable("API_BASE_URL") ?? "http://localhost:5000";
        Anonymous = new HttpClient { BaseAddress = new Uri(BaseUrl) };
    }

    public async Task InitializeAsync()
    {
        try
        {
            var ping = await Anonymous.GetAsync("/api/menu");
            ApiReachable = (int)ping.StatusCode < 500;
        }
        catch
        {
            ApiReachable = false;
            return;
        }

        var buyerEmail = Env("TEST_BUYER_EMAIL", "buyer@test.com");
        var buyerPwd = Env("TEST_BUYER_PASSWORD", "Buyer@123");
        var sellerEmail = Env("TEST_SELLER_EMAIL", "seller@test.com");
        var sellerPwd = Env("TEST_SELLER_PASSWORD", "Seller@123");
        var adminEmail = Env("TEST_ADMIN_EMAIL", "admin@stopnshop.com");
        var adminPwd = Env("TEST_ADMIN_PASSWORD", "Admin@123");

        BuyerToken = await TryLogin("/api/auth/login", buyerEmail, buyerPwd);
        SellerToken = await TryLogin("/api/auth/seller/login", sellerEmail, sellerPwd);
        AdminToken = await TryLogin("/api/auth/admin/login", adminEmail, adminPwd);

        Buyer = MakeClient(BuyerToken);
        Seller = MakeClient(SellerToken);
        Admin = MakeClient(AdminToken);
    }

    private HttpClient MakeClient(string? token)
    {
        var c = new HttpClient { BaseAddress = new Uri(BaseUrl) };
        if (!string.IsNullOrEmpty(token))
            c.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        return c;
    }

    private async Task<string?> TryLogin(string path, string email, string password)
    {
        try
        {
            var resp = await Anonymous.PostAsJsonAsync(path, new { email, password });
            if (!resp.IsSuccessStatusCode) return null;
            var json = await resp.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.TryGetProperty("data", out var data) && data.ValueKind == JsonValueKind.Object)
            {
                foreach (var prop in new[] { "token", "accessToken", "jwt" })
                    if (data.TryGetProperty(prop, out var t) && t.ValueKind == JsonValueKind.String)
                        return t.GetString();
            }
            return null;
        }
        catch { return null; }
    }

    private static string Env(string key, string fallback) =>
        Environment.GetEnvironmentVariable(key) is { Length: > 0 } v ? v : fallback;

    public Task DisposeAsync()
    {
        Anonymous.Dispose();
        Buyer?.Dispose();
        Seller?.Dispose();
        Admin?.Dispose();
        return Task.CompletedTask;
    }
}

[CollectionDefinition("Api")]
public sealed class ApiCollection : ICollectionFixture<ApiFixture> { }
