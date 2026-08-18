using System.Security.Claims;
using System.Security.Cryptography;
using Dapper;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

[ApiController]
[Route("api/admin")]
[Produces("application/json")]
public class AdminController(
    IConfiguration config,
    ICatalogueService catalogueService,
    ICouponService couponService,
    IAdminService adminService)
    : ControllerBase
{
    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));
    private string? ClientIp =>
        HttpContext?.Connection.RemoteIpAddress?.ToString();

    // ── One-time admin password setup ─────────────────────────────────────────

    /// <summary>
    /// Sets the admin password on first deployment.
    /// Only works when the current hash is the placeholder from the seed script.
    /// Call once: POST /api/admin/setup  { "password": "Admin@123" }
    /// </summary>
    [HttpPost("setup")]
    [AllowAnonymous]
    public async Task<IActionResult> Setup([FromBody] AdminSetupRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Password) || req.Password.Length < 8)
            return BadRequest(ApiResponse<object>.Fail("Password must be at least 8 characters."));

        using var db = Conn();

        var currentHash = await db.QuerySingleOrDefaultAsync<string>(
            "SELECT PasswordHash FROM Users WHERE Email = 'admin@stopnshop.com' AND IsDeleted = 0",
            commandType: System.Data.CommandType.Text);

        if (currentHash is null)
            return NotFound(ApiResponse<object>.Fail("Admin user not found."));

        if (!currentHash.StartsWith("$2a$12$PLACEHOLDER"))
            return BadRequest(ApiResponse<object>.Fail("Admin password is already set. Use change-password endpoint."));

        var hash = HashPassword(req.Password);
        await db.ExecuteAsync(
            "UPDATE Users SET PasswordHash = @Hash, UpdatedAt = GETUTCDATE() WHERE Email = 'admin@stopnshop.com'",
            new { Hash = hash },
            commandType: System.Data.CommandType.Text);

        return Ok(ApiResponse<object>.Ok(null, "Admin password set successfully. You can now login at POST /api/auth/buyer/login"));
    }

    // ── Product Approval ──────────────────────────────────────────────────────

    /// <summary>List all pending products awaiting admin approval.</summary>
    [HttpGet("products/pending")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetPendingProducts()
    {
        using var db = Conn();

        var products = await db.QueryAsync<PendingProductDto>(
            @"SELECT p.ProductId, p.ProductName, p.MRP, p.SellingPrice, p.ApprovalStatus,
                     p.CreatedAt, b.BrandName, c.CategoryName,
                     s.BusinessName AS SellerName, u.Email AS SellerEmail
              FROM Products p
              INNER JOIN Brands b ON b.BrandId = p.BrandId
              INNER JOIN Categories c ON c.CategoryId = p.CategoryId
              INNER JOIN Sellers s ON s.SellerId = p.SellerId
              INNER JOIN Users u ON u.UserId = s.UserId
              WHERE p.ApprovalStatus = 1 AND p.IsDeleted = 0
              ORDER BY p.CreatedAt DESC",
            commandType: System.Data.CommandType.Text);

        return Ok(ApiResponse<IEnumerable<PendingProductDto>>.Ok(products));
    }

    /// <summary>Approve a product — makes it visible to buyers.</summary>
    // ApproveProduct / RejectProduct now live in the Admin moderation block below
    // (HttpPatch routes that match the UI client). Old HttpPut variants removed.

    /// <summary>Approve ALL pending products at once (bulk approval for testing).</summary>
    [HttpPut("products/approve-all")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ApproveAllPending()
    {
        using var db = Conn();

        var count = await db.ExecuteAsync(
            @"UPDATE Products
              SET ApprovalStatus = 2, IsActive = 1, UpdatedAt = GETUTCDATE(), UpdatedBy = @UpdatedBy
              WHERE ApprovalStatus = 1 AND IsDeleted = 0",
            new { UpdatedBy = CurrentUserId },
            commandType: System.Data.CommandType.Text);

        return Ok(ApiResponse<object>.Ok(new { Approved = count }, $"{count} products approved."));
    }

    // ── CMS Banner Management ─────────────────────────────────────────────────

    /// <summary>Get all banners for admin panel (all sections, including inactive).</summary>
    [HttpGet("cms/banners")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAllBanners()
    {
        var banners = await catalogueService.GetAllBannersAdminAsync();
        return Ok(ApiResponse<List<CmsBannerDto>>.Ok(banners));
    }

    /// <summary>Create or update a banner.</summary>
    [HttpPost("cms/banners")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpsertBanner([FromBody] CmsBannerUpsertRequest req)
    {
        var bannerId = await catalogueService.UpsertBannerAsync(req, CurrentUserId);
        return Ok(ApiResponse<object>.Ok(new { BannerId = bannerId }, req.BannerId.HasValue ? "Banner updated." : "Banner created."));
    }

    /// <summary>Delete a banner (soft delete).</summary>
    [HttpDelete("cms/banners/{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteBanner(int id)
    {
        var success = await catalogueService.DeleteBannerAsync(id, CurrentUserId);
        if (!success)
            return NotFound(ApiResponse<object>.Fail("Banner not found."));

        return Ok(ApiResponse<object>.Ok(null, "Banner deleted."));
    }

    /// <summary>Upload image to ImgBB and return public URL.</summary>
    [HttpPost("cms/banners/upload-image")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UploadBannerImage(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(ApiResponse<object>.Fail("No file provided."));

        if (file.Length > 10 * 1024 * 1024) // 10MB limit
            return BadRequest(ApiResponse<object>.Fail("File size exceeds 10MB limit."));

        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
        var fileExt = Path.GetExtension(file.FileName).ToLower();
        if (!allowedExtensions.Contains(fileExt))
            return BadRequest(ApiResponse<object>.Fail("Invalid file type. Only images allowed."));

        try
        {
            var imgbbApiKey = config.GetValue<string>("ImgBB:ApiKey");
            if (string.IsNullOrEmpty(imgbbApiKey))
                return StatusCode(500, ApiResponse<object>.Fail("ImgBB API key not configured."));

            using var memoryStream = new MemoryStream();
            await file.CopyToAsync(memoryStream);
            var base64Image = Convert.ToBase64String(memoryStream.ToArray());

            using var client = new HttpClient();
            var formContent = new MultipartFormDataContent
            {
                { new StringContent(base64Image), "image" },
                { new StringContent(imgbbApiKey), "key" }
            };

            var response = await client.PostAsync("https://api.imgbb.com/1/upload", formContent);
            if (!response.IsSuccessStatusCode)
                return StatusCode(500, ApiResponse<object>.Fail("Failed to upload image to ImgBB."));

            var responseContent = await response.Content.ReadAsStringAsync();
            using var jsonDoc = System.Text.Json.JsonDocument.Parse(responseContent);
            var root = jsonDoc.RootElement;
            var imageUrl = root.GetProperty("data").GetProperty("display_url").GetString();

            return Ok(ApiResponse<object>.Ok(new { ImageUrl = imageUrl }, "Image uploaded successfully."));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<object>.Fail($"Error uploading image: {ex.Message}"));
        }
    }

    // ── Dashboard / listings / moderation ─────────────────────────────────────

    private static IActionResult Paged<T>(List<T> items, int total, int page, int pageSize)
        => new OkObjectResult(ApiResponse<object>.Ok(new
        {
            items,
            totalCount = total,
            pageNo     = page,
            pageSize,
        }));

    [HttpGet("dashboard")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Dashboard()
    {
        var stats = await adminService.GetDashboardStatsAsync();
        return Ok(ApiResponse<AdminStatsDto>.Ok(stats));
    }

    [HttpGet("sellers")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetSellers(
        [FromQuery] int pageNo = 1, [FromQuery] int pageSize = 20,
        [FromQuery] byte? approvalStatus = null, [FromQuery] string? search = null)
    {
        var (items, total) = await adminService.GetSellersAsync(pageNo, pageSize, approvalStatus, search);
        return Paged(items, total, pageNo, pageSize);
    }

    [HttpPatch("sellers/{id:int}/approve")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ApproveSeller(int id)
    {
        try { await adminService.ApproveSellerAsync(id, CurrentUserId, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "Seller approved.")); }
        catch (SqlException ex) when (ex.Number == 50110) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("sellers/{id:int}/reject")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> RejectSeller(int id, [FromBody] RejectReasonRequest? req)
    {
        try { await adminService.RejectSellerAsync(id, CurrentUserId, req?.Reason, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "Seller rejected.")); }
        catch (SqlException ex) when (ex.Number == 50110) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("sellers/{id:int}/suspend")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SuspendSeller(int id)
    {
        try { await adminService.SuspendSellerAsync(id, CurrentUserId, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "Seller suspended.")); }
        catch (SqlException ex) when (ex.Number == 50110) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpGet("sellers/{id:int}/score")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetSellerScore(int id, [FromQuery] DateTime? from = null, [FromQuery] DateTime? to = null)
    {
        try
        {
            var score = await adminService.GetSellerScoreAsync(id, from, to);
            return Ok(ApiResponse<AdminSellerScoreDto>.Ok(score));
        }
        catch (SqlException ex) when (ex.Number == 50140)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }

    [HttpGet("products")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetProducts(
        [FromQuery] int pageNo = 1, [FromQuery] int pageSize = 20,
        [FromQuery] byte? approvalStatus = null, [FromQuery] string? search = null)
    {
        var (items, total) = await adminService.GetProductsAsync(pageNo, pageSize, approvalStatus, search);
        return Paged(items, total, pageNo, pageSize);
    }

    [HttpPatch("products/{id:int}/approve")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ApproveProduct(int id)
    {
        try { await adminService.ApproveProductAsync(id, CurrentUserId, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "Product approved.")); }
        catch (SqlException ex) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("products/{id:int}/reject")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> RejectProduct(int id, [FromBody] RejectReasonRequest? req)
    {
        try { await adminService.RejectProductAsync(id, CurrentUserId, req?.Reason, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "Product rejected.")); }
        catch (SqlException ex) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpGet("products/moderation-queue")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetProductModerationQueue(
        [FromQuery] int pageNo = 1, [FromQuery] int pageSize = 20)
    {
        var (items, total) = await adminService.GetProductModerationQueueAsync(pageNo, pageSize);
        return Paged(items, total, pageNo, pageSize);
    }

    [HttpGet("users")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetUsers(
        [FromQuery] int pageNo = 1, [FromQuery] int pageSize = 20,
        [FromQuery] byte? roleId = null, [FromQuery] string? search = null)
    {
        var (items, total) = await adminService.GetUsersAsync(pageNo, pageSize, roleId, search);
        return Paged(items, total, pageNo, pageSize);
    }

    [HttpPatch("users/{id:int}/suspend")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SuspendUser(int id, [FromBody] SuspendUserRequest? req)
    {
        try { await adminService.SuspendUserAsync(id, CurrentUserId, req?.Reason, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "User suspended.")); }
        catch (SqlException ex) when (ex.Number is 50130 or 50131) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("users/{id:int}/activate")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ActivateUser(int id)
    {
        try { await adminService.ActivateUserAsync(id, CurrentUserId, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "User activated.")); }
        catch (SqlException ex) when (ex.Number == 50132) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpDelete("users/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SoftDeleteUser(int id)
    {
        try { await adminService.SoftDeleteUserAsync(id, CurrentUserId, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "User deleted.")); }
        catch (SqlException ex) when (ex.Number is 50133 or 50134) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpGet("orders")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetOrders(
        [FromQuery] int pageNo = 1, [FromQuery] int pageSize = 20,
        [FromQuery] byte? status = null, [FromQuery] string? search = null,
        [FromQuery] string? lineStatus = null,        // 'unfulfilled' | 'rejected'
        [FromQuery] string? paymentStatus = null)     // 'paid'
    {
        byte? lineStatusFilter = lineStatus?.ToLowerInvariant() switch
        {
            "unfulfilled" => (byte?)1,
            "rejected"    => (byte?)8,
            _             => null,
        };
        byte? paymentStatusFilter = paymentStatus?.ToLowerInvariant() switch
        {
            "paid"       => (byte?)2,
            "unpaid"     => (byte?)1,
            "refunded"   => (byte?)3,
            _            => null,
        };

        var (items, total) = await adminService.GetOrdersAsync(pageNo, pageSize, status, search, lineStatusFilter, paymentStatusFilter);
        return Paged(items, total, pageNo, pageSize);
    }

    [HttpPatch("orders/{id:int}/force-cancel")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ForceCancelOrder(int id, [FromBody] ForceCancelOrderRequest req)
    {
        try { await adminService.ForceCancelOrderAsync(id, CurrentUserId, req, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "Order force-cancelled.")); }
        catch (ValidationException ex)             { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
        catch (SqlException ex) when (ex.Number == 50150) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
        catch (SqlException ex) when (ex.Number == 50151) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("orders/{id:int}/refund")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> RefundOrder(int id, [FromBody] ManualRefundRequest req)
    {
        try { await adminService.ManualRefundOrderAsync(id, CurrentUserId, req, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "Refund recorded.")); }
        catch (ValidationException ex)                                 { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
        catch (SqlException ex) when (ex.Number == 50160)              { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
        catch (SqlException ex) when (ex.Number is >= 50161 and <= 50163) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpGet("reviews")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetReviews(
        [FromQuery] int pageNo = 1, [FromQuery] int pageSize = 20,
        [FromQuery] bool? isApproved = null)
    {
        var (items, total) = await adminService.GetReviewsAsync(pageNo, pageSize, isApproved);
        return Paged(items, total, pageNo, pageSize);
    }

    [HttpPatch("reviews/{id:int}/approve")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ApproveReview(int id)
    {
        await adminService.ApproveReviewAsync(id, CurrentUserId, ClientIp);
        return Ok(ApiResponse<object>.Ok(null!, "Review approved."));
    }

    // ── Audit ─────────────────────────────────────────────────────────────────

    [HttpGet("audit")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> QueryAudit(
        [FromQuery] string? tableName = null,
        [FromQuery] int?    recordId  = null,
        [FromQuery] int?    changedBy = null,
        [FromQuery] DateTime? from = null,
        [FromQuery] DateTime? to   = null,
        [FromQuery] int pageNo   = 1,
        [FromQuery] int pageSize = 20)
    {
        var (items, total) = await adminService.QueryAuditAsync(tableName, recordId, changedBy, from, to, pageNo, pageSize);
        return Paged(items, total, pageNo, pageSize);
    }

    // ── Coupons CRUD ──────────────────────────────────────────────────────────

    /// <summary>List all coupons (active + disabled) for the admin coupons screen.</summary>
    [HttpGet("coupons")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ListCoupons([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var (items, total) = await couponService.GetAllAsync(page, pageSize);
        return Ok(ApiResponse<object>.Ok(new { items, totalCount = total, page, pageSize }));
    }

    /// <summary>Create a new coupon. Brand-specific coupons require ApplicableOn=2 and a brand EntityId.</summary>
    [HttpPost("coupons")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CreateCoupon([FromBody] CreateCouponRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.CouponCode))
            return BadRequest(ApiResponse<object>.Fail("Coupon code is required."));
        if (req.DiscountValue <= 0)
            return BadRequest(ApiResponse<object>.Fail("Discount value must be greater than 0."));
        if (req.EndDate <= req.StartDate)
            return BadRequest(ApiResponse<object>.Fail("End date must be after start date."));

        try
        {
            var id = await couponService.CreateAsync(req, CurrentUserId);
            return Ok(ApiResponse<object>.Ok(new { couponId = id }, "Coupon created."));
        }
        catch (SqlException ex) when (ex.Number is 50080 or 50081)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Enable or disable a coupon. Disabling also disables the parent Offer.</summary>
    [HttpPatch("coupons/{id:int}/toggle")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ToggleCoupon(int id, [FromBody] ToggleCouponRequest req)
    {
        try
        {
            await couponService.ToggleAsync(id, req.IsActive, CurrentUserId);
            return Ok(ApiResponse<object>.Ok(null, req.IsActive ? "Coupon enabled." : "Coupon disabled."));
        }
        catch (SqlException ex) when (ex.Number == 50082)
        {
            return NotFound(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Update coupon details (code, name, dates, discount, applicability).</summary>
    [HttpPut("coupons/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateCoupon(int id, [FromBody] UpdateCouponRequest req)
    {
        try { await adminService.UpdateCouponAsync(id, req, CurrentUserId, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "Coupon updated.")); }
        catch (ValidationException ex)                                 { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
        catch (SqlException ex) when (ex.Number is 50090 or 50091 or 50092) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    /// <summary>Soft-delete a coupon and its parent Offer.</summary>
    [HttpDelete("coupons/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteCoupon(int id)
    {
        try { await adminService.DeleteCouponAsync(id, CurrentUserId, ClientIp); return Ok(ApiResponse<object>.Ok(null!, "Coupon deleted.")); }
        catch (SqlException ex) when (ex.Number == 50095) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    private static string HashPassword(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(16);
        var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, 100_000, HashAlgorithmName.SHA256, 32);
        return $"{Convert.ToBase64String(salt)}:{Convert.ToBase64String(hash)}";
    }
}

public record AdminSetupRequest(string Password);
public record RejectProductRequest(string Reason);

public class PendingProductDto
{
    public int      ProductId      { get; set; }
    public string   ProductName    { get; set; } = string.Empty;
    public decimal  MRP            { get; set; }
    public decimal  SellingPrice   { get; set; }
    public int      ApprovalStatus { get; set; }
    public DateTime CreatedAt      { get; set; }
    public string?  BrandName      { get; set; }
    public string?  CategoryName   { get; set; }
    public string?  SellerName     { get; set; }
    public string?  SellerEmail    { get; set; }
}
