using System.Net;
using System.Text;
using FluentAssertions;
using Xunit;
using Xunit.Abstractions;

namespace StopNShop.Api.IntegrationTests;

/// <summary>
/// Pre-push smoke. One test per endpoint asserting status &lt; 500 (no server crash).
/// 4xx is acceptable — it means the route exists, the pipeline ran, and the handler
/// rejected the input cleanly. We are not exhaustively validating business logic here.
/// Run against a live API: dotnet test (set API_BASE_URL env var to override default).
/// </summary>
[Collection("Api")]
public class EndpointTests
{
    private readonly ApiFixture _fx;
    private readonly ITestOutputHelper _log;

    public EndpointTests(ApiFixture fx, ITestOutputHelper log)
    {
        _fx = fx;
        _log = log;
    }

    private void RequireApi()
    {
        if (!_fx.ApiReachable)
            Assert.Fail($"API not reachable at {_fx.BaseUrl}. Start it with: cd api && dotnet run");
    }

    private HttpClient ClientFor(string role) => role switch
    {
        "buyer" => _fx.Buyer,
        "seller" => _fx.Seller,
        "admin" => _fx.Admin,
        _ => _fx.Anonymous,
    };

    private async Task AssertNoServerError(string role, HttpMethod method, string path, string? jsonBody = null)
    {
        RequireApi();
        var client = ClientFor(role);
        using var req = new HttpRequestMessage(method, path);
        if (jsonBody is not null)
            req.Content = new StringContent(jsonBody, Encoding.UTF8, "application/json");
        var resp = await client.SendAsync(req);
        _log.WriteLine($"{method} {path} [{role}] => {(int)resp.StatusCode} {resp.StatusCode}");
        ((int)resp.StatusCode).Should().BeLessThan(500, $"{method} {path} returned 5xx");
    }

    // ───────────────────────── Catalogue (anonymous) ─────────────────────────
    [Fact] public Task Get_Menu()                       => AssertNoServerError("anon", HttpMethod.Get, "/api/menu");
    [Fact] public Task Get_Banners()                    => AssertNoServerError("anon", HttpMethod.Get, "/api/banners");
    [Fact] public Task Get_Stores()                     => AssertNoServerError("anon", HttpMethod.Get, "/api/stores");
    [Fact] public Task Get_PincodeCheck()               => AssertNoServerError("anon", HttpMethod.Get, "/api/pincode/110001");
    [Fact] public Task Get_Categories()                 => AssertNoServerError("anon", HttpMethod.Get, "/api/categories");
    [Fact] public Task Get_SubCategories()              => AssertNoServerError("anon", HttpMethod.Get, "/api/categories/1/subcategories");

    // ───────────────────────── Products (anonymous) ─────────────────────────
    [Fact] public Task Get_ProductsList()               => AssertNoServerError("anon", HttpMethod.Get, "/api/products?page=1&pageSize=10");
    [Fact] public Task Get_ProductDetail()              => AssertNoServerError("anon", HttpMethod.Get, "/api/products/1");
    [Fact] public Task Get_ProductOffersMaster()        => AssertNoServerError("anon", HttpMethod.Get, "/api/products/offers/master");
    [Fact] public Task Get_ProductSimilar()             => AssertNoServerError("anon", HttpMethod.Get, "/api/products/1/similar");
    [Fact] public Task Get_ProductsRecommended()        => AssertNoServerError("anon", HttpMethod.Get, "/api/products/recommended");

    // ───────────────────────── Brands ─────────────────────────
    [Fact] public Task Get_Brands()                     => AssertNoServerError("anon", HttpMethod.Get, "/api/brands");

    // ───────────────────────── Reviews ─────────────────────────
    [Fact] public Task Get_ProductReviews()             => AssertNoServerError("anon", HttpMethod.Get, "/api/products/1/reviews");
    [Fact] public Task Post_ProductReview()             => AssertNoServerError("buyer", HttpMethod.Post, "/api/products/1/reviews", "{}");

    // ───────────────────────── Auth (anonymous) ─────────────────────────
    [Fact] public Task Post_BuyerRegister()             => AssertNoServerError("anon", HttpMethod.Post, "/api/auth/buyer/register", "{}");
    [Fact] public Task Post_BuyerLogin()                => AssertNoServerError("anon", HttpMethod.Post, "/api/auth/buyer/login", "{}");
    [Fact] public Task Post_SellerLogin()               => AssertNoServerError("anon", HttpMethod.Post, "/api/auth/seller/login", "{}");
    [Fact] public Task Post_AdminLogin()                => AssertNoServerError("anon", HttpMethod.Post, "/api/auth/admin/login", "{}");
    [Fact] public Task Post_OtpSend()                   => AssertNoServerError("anon", HttpMethod.Post, "/api/auth/otp/send", "{}");
    [Fact] public Task Post_OtpVerify()                 => AssertNoServerError("anon", HttpMethod.Post, "/api/auth/otp/verify", "{}");
    [Fact] public Task Post_ForgotPassword()            => AssertNoServerError("anon", HttpMethod.Post, "/api/auth/forgot-password", "{}");
    [Fact] public Task Post_ForgotPasswordVerifyOtp()   => AssertNoServerError("anon", HttpMethod.Post, "/api/auth/forgot-password/verify-otp", "{}");
    [Fact] public Task Post_ResetPassword()             => AssertNoServerError("anon", HttpMethod.Post, "/api/auth/reset-password", "{}");
    [Fact] public Task Get_AuthProfile()                => AssertNoServerError("buyer", HttpMethod.Get, "/api/auth/profile");
    [Fact] public Task Get_AuthMe()                     => AssertNoServerError("buyer", HttpMethod.Get, "/api/auth/me");
    [Fact] public Task Put_AuthProfile()                => AssertNoServerError("buyer", HttpMethod.Put, "/api/auth/profile", "{}");
    [Fact] public Task Post_MarkFirstLoginComplete()    => AssertNoServerError("buyer", HttpMethod.Post, "/api/auth/mark-first-login-complete", "{}");

    // ───────────────────────── Addresses (buyer) ─────────────────────────
    [Fact] public Task Get_Addresses()                  => AssertNoServerError("buyer", HttpMethod.Get, "/api/addresses");
    [Fact] public Task Post_Address()                   => AssertNoServerError("buyer", HttpMethod.Post, "/api/addresses", "{}");
    [Fact] public Task Put_AddressDefault()             => AssertNoServerError("buyer", HttpMethod.Put, "/api/addresses/1/default");

    // ───────────────────────── Cart (buyer) ─────────────────────────
    [Fact] public Task Get_Cart()                       => AssertNoServerError("buyer", HttpMethod.Get, "/api/cart");
    [Fact] public Task Post_CartAdd()                   => AssertNoServerError("buyer", HttpMethod.Post, "/api/cart", "{}");
    [Fact] public Task Put_CartUpdate()                 => AssertNoServerError("buyer", HttpMethod.Put, "/api/cart/1", "{}");
    [Fact] public Task Delete_CartItem()                => AssertNoServerError("buyer", HttpMethod.Delete, "/api/cart/1");

    // ───────────────────────── Wishlist (buyer) ─────────────────────────
    [Fact] public Task Get_Wishlist()                   => AssertNoServerError("buyer", HttpMethod.Get, "/api/wishlist");
    [Fact] public Task Post_Wishlist()                  => AssertNoServerError("buyer", HttpMethod.Post, "/api/wishlist/1", "{}");

    // ───────────────────────── Orders (buyer) ─────────────────────────
    [Fact] public Task Post_PlaceOrder()                => AssertNoServerError("buyer", HttpMethod.Post, "/api/orders", "{}");
    [Fact] public Task Get_Orders()                     => AssertNoServerError("buyer", HttpMethod.Get, "/api/orders");
    [Fact] public Task Get_OrderById()                  => AssertNoServerError("buyer", HttpMethod.Get, "/api/orders/1");
    [Fact] public Task Delete_Order()                   => AssertNoServerError("buyer", HttpMethod.Delete, "/api/orders/1");

    // ───────────────────────── Coupons (buyer) ─────────────────────────
    [Fact] public Task Post_CouponValidate()            => AssertNoServerError("buyer", HttpMethod.Post, "/api/coupons/validate", "{}");

    // ───────────────────────── Wallet ─────────────────────────
    [Fact] public Task Get_Wallet()                     => AssertNoServerError("buyer", HttpMethod.Get, "/api/wallet");

    // ───────────────────────── Notifications ─────────────────────────
    [Fact] public Task Get_Notifications()              => AssertNoServerError("buyer", HttpMethod.Get, "/api/notifications");
    [Fact] public Task Patch_NotificationRead()         => AssertNoServerError("buyer", HttpMethod.Patch, "/api/notifications/1/read");
    [Fact] public Task Patch_NotificationsReadAll()     => AssertNoServerError("buyer", HttpMethod.Patch, "/api/notifications/read-all");

    // ───────────────────────── Seller Auth ─────────────────────────
    [Fact] public Task Post_SellerAuthSignup()          => AssertNoServerError("anon", HttpMethod.Post, "/api/seller/auth/signup", "{}");
    [Fact] public Task Post_SellerAuthLogin()           => AssertNoServerError("anon", HttpMethod.Post, "/api/seller/auth/login", "{}");
    [Fact] public Task Get_SellerAuthProfile()          => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/auth/profile");
    [Fact] public Task Put_SellerAuthProfile()          => AssertNoServerError("seller", HttpMethod.Put, "/api/seller/auth/profile", "{}");
    [Fact] public Task Post_SellerAuthOnboarding()      => AssertNoServerError("seller", HttpMethod.Post, "/api/seller/auth/onboarding", "{}");

    // ───────────────────────── Seller ─────────────────────────
    [Fact] public Task Post_SellerOnboarding()          => AssertNoServerError("seller", HttpMethod.Post, "/api/seller/onboarding", "{}");
    [Fact] public Task Get_SellerProfile()              => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/profile");
    [Fact] public Task Put_SellerProfile()              => AssertNoServerError("seller", HttpMethod.Put, "/api/seller/profile", "{}");

    // ───────────────────────── Seller Dashboard / Analytics / Inventory ─────────────────────────
    [Fact] public Task Get_SellerDashboard()            => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/dashboard");
    [Fact] public Task Get_SellerAnalytics()            => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/analytics");
    [Fact] public Task Post_SellerAnalyticsAggregate()  => AssertNoServerError("seller", HttpMethod.Post, "/api/seller/analytics/aggregate", "{}");
    [Fact] public Task Get_SellerInventory()            => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/inventory");
    [Fact] public Task Get_SellerInventoryLowStock()    => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/inventory/low-stock");

    // ───────────────────────── Seller Products ─────────────────────────
    [Fact] public Task Get_SellerProducts()             => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/products?page=1&pageSize=10");
    [Fact] public Task Get_SellerProductById()          => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/products/1");
    [Fact] public Task Post_SellerProduct()             => AssertNoServerError("seller", HttpMethod.Post, "/api/seller/products", "{}");
    [Fact] public Task Put_SellerProduct()              => AssertNoServerError("seller", HttpMethod.Put, "/api/seller/products/1", "{}");
    [Fact] public Task Delete_SellerProduct()           => AssertNoServerError("seller", HttpMethod.Delete, "/api/seller/products/1");
    [Fact] public Task Patch_SellerProductInventory()   => AssertNoServerError("seller", HttpMethod.Patch, "/api/seller/products/1/inventory", "{}");

    // ───────────────────────── Seller Orders ─────────────────────────
    [Fact] public Task Get_SellerOrders()               => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/orders");
    [Fact] public Task Get_SellerOrderById()            => AssertNoServerError("seller", HttpMethod.Get, "/api/seller/orders/1");
    [Fact] public Task Patch_SellerOrderStatus()        => AssertNoServerError("seller", HttpMethod.Patch, "/api/seller/orders/1/status", "{}");
    [Fact] public Task Patch_SellerOrderUpdateStatus()  => AssertNoServerError("seller", HttpMethod.Patch, "/api/seller/orders/update/1/status", "{}");
    [Fact] public Task Post_SellerOrderCancel()         => AssertNoServerError("seller", HttpMethod.Post, "/api/seller/orders/1/cancel", "{}");

    // ───────────────────────── Admin ─────────────────────────
    [Fact] public Task Post_AdminSetup()                => AssertNoServerError("anon", HttpMethod.Post, "/api/admin/setup", "{}");
    [Fact] public Task Get_AdminDashboard()             => AssertNoServerError("admin", HttpMethod.Get, "/api/admin/dashboard");
    [Fact] public Task Get_AdminProductsPending()       => AssertNoServerError("admin", HttpMethod.Get, "/api/admin/products/pending");
    [Fact] public Task Put_AdminProductsApproveAll()    => AssertNoServerError("admin", HttpMethod.Put, "/api/admin/products/approve-all", "{}");
    [Fact] public Task Get_AdminProducts()              => AssertNoServerError("admin", HttpMethod.Get, "/api/admin/products");
    [Fact] public Task Patch_AdminProductApprove()      => AssertNoServerError("admin", HttpMethod.Patch, "/api/admin/products/1/approve");
    [Fact] public Task Patch_AdminProductReject()       => AssertNoServerError("admin", HttpMethod.Patch, "/api/admin/products/1/reject", "{}");
    [Fact] public Task Get_AdminSellers()               => AssertNoServerError("admin", HttpMethod.Get, "/api/admin/sellers");
    [Fact] public Task Patch_AdminSellerApprove()       => AssertNoServerError("admin", HttpMethod.Patch, "/api/admin/sellers/1/approve");
    [Fact] public Task Patch_AdminSellerReject()        => AssertNoServerError("admin", HttpMethod.Patch, "/api/admin/sellers/1/reject", "{}");
    [Fact] public Task Patch_AdminSellerSuspend()       => AssertNoServerError("admin", HttpMethod.Patch, "/api/admin/sellers/1/suspend");
    [Fact] public Task Get_AdminUsers()                 => AssertNoServerError("admin", HttpMethod.Get, "/api/admin/users");
    [Fact] public Task Get_AdminOrders()                => AssertNoServerError("admin", HttpMethod.Get, "/api/admin/orders");
    [Fact] public Task Get_AdminReviews()               => AssertNoServerError("admin", HttpMethod.Get, "/api/admin/reviews");
    [Fact] public Task Patch_AdminReviewApprove()       => AssertNoServerError("admin", HttpMethod.Patch, "/api/admin/reviews/1/approve");
    [Fact] public Task Get_AdminCoupons()               => AssertNoServerError("admin", HttpMethod.Get, "/api/admin/coupons");
    [Fact] public Task Post_AdminCoupon()               => AssertNoServerError("admin", HttpMethod.Post, "/api/admin/coupons", "{}");
    [Fact] public Task Patch_AdminCouponToggle()        => AssertNoServerError("admin", HttpMethod.Patch, "/api/admin/coupons/1/toggle");
    [Fact] public Task Get_AdminCmsBanners()            => AssertNoServerError("admin", HttpMethod.Get, "/api/admin/cms/banners");
    [Fact] public Task Post_AdminCmsBanner()            => AssertNoServerError("admin", HttpMethod.Post, "/api/admin/cms/banners", "{}");
    [Fact] public Task Delete_AdminCmsBanner()          => AssertNoServerError("admin", HttpMethod.Delete, "/api/admin/cms/banners/1");

    // ───────────────────────── Inventory ─────────────────────────
    [Fact] public Task Get_InventoryWarehouses_Admin()    => AssertNoServerError("admin",  HttpMethod.Get,   "/api/inventory/warehouses");
    [Fact] public Task Get_InventoryWarehouses_Seller()   => AssertNoServerError("seller", HttpMethod.Get,   "/api/inventory/warehouses");
    [Fact] public Task Get_InventoryMatrix()              => AssertNoServerError("admin",  HttpMethod.Get,   "/api/inventory/matrix?pageNo=1&pageSize=10");
    [Fact] public Task Get_InventoryLowStock()            => AssertNoServerError("admin",  HttpMethod.Get,   "/api/inventory/low-stock");
    [Fact] public Task Get_InventoryStockByVariant()      => AssertNoServerError("admin",  HttpMethod.Get,   "/api/inventory/variants/1/stock");
    [Fact] public Task Get_InventoryMovements()           => AssertNoServerError("admin",  HttpMethod.Get,   "/api/inventory/variants/1/movements");
    [Fact] public Task Post_InventoryAdjust()             => AssertNoServerError("admin",  HttpMethod.Post,  "/api/inventory/stock/adjust",  "{}");
    [Fact] public Task Post_InventoryReserve()            => AssertNoServerError("buyer",  HttpMethod.Post,  "/api/inventory/stock/reserve", "{}");
    [Fact] public Task Post_InventoryRelease()            => AssertNoServerError("buyer",  HttpMethod.Post,  "/api/inventory/stock/release", "{}");
    [Fact] public Task Post_InventoryTransfer()           => AssertNoServerError("admin",  HttpMethod.Post,  "/api/inventory/transfers",     "{}");
    [Fact] public Task Patch_InventoryTransferReceive()   => AssertNoServerError("admin",  HttpMethod.Patch, "/api/inventory/transfers/1/receive");

    // ───────────────────────── Catalog extras ─────────────────────────
    [Fact] public Task Get_FeaturedSubCategories()        => AssertNoServerError("anon",   HttpMethod.Get,  "/api/catalog/subcategories/featured?count=10");
    [Fact] public Task Get_SubCategoryFormSchema()        => AssertNoServerError("anon",   HttpMethod.Get,  "/api/catalog/subcategories/1/form-schema");
    [Fact] public Task Get_SubCategoryVariantOptions()    => AssertNoServerError("anon",   HttpMethod.Get,  "/api/catalog/subcategories/1/variant-options");

    // ───────────────────────── Coupons (customer-visible) ─────────────────────────
    [Fact] public Task Get_CouponsAvailable()             => AssertNoServerError("buyer",  HttpMethod.Get,  "/api/coupons/available");

    // ───────────────────────── Payments / Razorpay ─────────────────────────
    [Fact] public Task Post_RazorpayCreateOrder()         => AssertNoServerError("buyer",  HttpMethod.Post, "/api/payments/razorpay/create-order", "{\"amount\":100}");

    // ───────────────────────── Engagement ─────────────────────────
    [Fact] public Task Get_RecentSearches()               => AssertNoServerError("buyer",  HttpMethod.Get,  "/api/engagement/recent-searches");

    // ───────────────────────── Complaints ─────────────────────────
    [Fact] public Task Get_ComplaintsMine()               => AssertNoServerError("buyer",  HttpMethod.Get,  "/api/complaints/mine");
    [Fact] public Task Post_ComplaintsCreate()            => AssertNoServerError("buyer",  HttpMethod.Post, "/api/complaints", "{}");
    [Fact] public Task Get_AdminComplaints()              => AssertNoServerError("admin",  HttpMethod.Get,  "/api/admin/complaints");

    // ───────────────────────── Admin Categories ─────────────────────────
    [Fact] public Task Get_AdminCategoriesTree()          => AssertNoServerError("admin",  HttpMethod.Get,  "/api/admin/categories");
    [Fact] public Task Post_AdminCategory()               => AssertNoServerError("admin",  HttpMethod.Post, "/api/admin/categories", "{}");
    [Fact] public Task Put_AdminCategory()                => AssertNoServerError("admin",  HttpMethod.Put,  "/api/admin/categories/1", "{}");
    [Fact] public Task Post_AdminSubCategory()            => AssertNoServerError("admin",  HttpMethod.Post, "/api/admin/categories/subcategories", "{}");
    [Fact] public Task Put_AdminSubCategory()             => AssertNoServerError("admin",  HttpMethod.Put,  "/api/admin/categories/subcategories/1", "{}");
    [Fact] public Task Delete_AdminSubCategory()          => AssertNoServerError("admin",  HttpMethod.Delete, "/api/admin/categories/subcategories/1");

    // ───────────────────────── Admin Variant Library ─────────────────────────
    [Fact] public Task Get_AdminVariantAttributes()       => AssertNoServerError("admin",  HttpMethod.Get,  "/api/admin/variant-library/attributes");
    [Fact] public Task Get_AdminVariantOptions()          => AssertNoServerError("admin",  HttpMethod.Get,  "/api/admin/variant-library/options");
    [Fact] public Task Post_AdminVariantOption()          => AssertNoServerError("admin",  HttpMethod.Post, "/api/admin/variant-library/options", "{}");
    [Fact] public Task Delete_AdminVariantOption()        => AssertNoServerError("admin",  HttpMethod.Delete, "/api/admin/variant-library/options/1");

    // ───────────────────────── Admin Audit ─────────────────────────
    [Fact] public Task Get_AdminAudit()                   => AssertNoServerError("admin",  HttpMethod.Get,  "/api/admin/audit");

    // ───────────────────────── Admin Orders extras ─────────────────────────
    [Fact] public Task Patch_AdminOrderForceCancel()      => AssertNoServerError("admin",  HttpMethod.Patch, "/api/admin/orders/1/force-cancel", "{}");
    [Fact] public Task Patch_AdminOrderRefund()           => AssertNoServerError("admin",  HttpMethod.Patch, "/api/admin/orders/1/refund", "{}");

    // ───────────────────────── Seller extras ─────────────────────────
    [Fact] public Task Get_SellerAgreementLatest()        => AssertNoServerError("seller", HttpMethod.Get,  "/api/seller/agreement/latest");
    [Fact] public Task Get_SellerBankAccounts()           => AssertNoServerError("seller", HttpMethod.Get,  "/api/seller/bank-accounts");
    [Fact] public Task Get_SellerPerformanceScore()       => AssertNoServerError("seller", HttpMethod.Get,  "/api/seller/performance-score");
    [Fact] public Task Get_SellerSettlements()            => AssertNoServerError("seller", HttpMethod.Get,  "/api/seller/settlements");
    [Fact] public Task Get_SellerProductVariantOptions()  => AssertNoServerError("seller", HttpMethod.Get,  "/api/seller/products/1/variant-options");
    [Fact] public Task Get_SellerOrderItems()             => AssertNoServerError("seller", HttpMethod.Get,  "/api/seller/orders/items");
    [Fact] public Task Get_SellerOrderLabelData()         => AssertNoServerError("seller", HttpMethod.Get,  "/api/seller/orders/items/1/label-data");

    // ───────────────────────── Wallet/Notifications extras ─────────────────────────
    [Fact] public Task Post_WalletClaimWelcome()          => AssertNoServerError("buyer",  HttpMethod.Post, "/api/wallet/claim-welcome", "{}");
}
