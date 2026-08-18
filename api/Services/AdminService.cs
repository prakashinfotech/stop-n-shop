using System.Text.Json;
using FluentValidation;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IAdminService
{
    // Reads
    Task<AdminStatsDto> GetDashboardStatsAsync();
    Task<(List<AdminSellerDto> Items, int Total)> GetSellersAsync(int page, int pageSize, byte? approvalStatus, string? search);
    Task<(List<AdminProductDto> Items, int Total)> GetProductsAsync(int page, int pageSize, byte? approvalStatus, string? search);
    Task<(List<AdminProductDto> Items, int Total)> GetProductModerationQueueAsync(int page, int pageSize);
    Task<(List<AdminUserDto>    Items, int Total)> GetUsersAsync(int page, int pageSize, byte? roleId, string? search);
    Task<(List<AdminOrderDto>   Items, int Total)> GetOrdersAsync(int page, int pageSize, byte? status, string? search, byte? lineStatusFilter = null, byte? paymentStatusFilter = null);
    Task<(List<AdminReviewDto>  Items, int Total)> GetReviewsAsync(int page, int pageSize, bool? isApproved);
    Task<AdminSellerScoreDto> GetSellerScoreAsync(int sellerId, DateTime? from, DateTime? to);
    Task<(List<AdminAuditEntryDto> Items, int Total)> QueryAuditAsync(string? tableName, int? recordId, int? changedBy, DateTime? from, DateTime? to, int page, int pageSize);

    // Writes (all audited)
    Task ApproveSellerAsync(int sellerId, int adminUserId, string? ipAddress);
    Task RejectSellerAsync(int sellerId, int adminUserId, string? reason, string? ipAddress);
    Task SuspendSellerAsync(int sellerId, int adminUserId, string? ipAddress);
    Task ApproveProductAsync(int productId, int adminUserId, string? ipAddress);
    Task RejectProductAsync(int productId, int adminUserId, string? reason, string? ipAddress);
    Task ApproveReviewAsync(int reviewId, int adminUserId, string? ipAddress);

    Task SuspendUserAsync(int userId, int adminUserId, string? reason, string? ipAddress);
    Task ActivateUserAsync(int userId, int adminUserId, string? ipAddress);
    Task SoftDeleteUserAsync(int userId, int adminUserId, string? ipAddress);

    Task ForceCancelOrderAsync(int orderId, int adminUserId, ForceCancelOrderRequest req, string? ipAddress);
    Task ManualRefundOrderAsync(int orderId, int adminUserId, ManualRefundRequest req, string? ipAddress);

    Task UpdateCouponAsync(int couponId, UpdateCouponRequest req, int adminUserId, string? ipAddress);
    Task DeleteCouponAsync(int couponId, int adminUserId, string? ipAddress);
}

/// <summary>
/// Admin write operations route through this service so every mutating admin
/// action records an entry in AuditLogs via <see cref="IAdminRepository.WriteAuditAsync"/>.
/// Reads pass straight through to the repository.
/// </summary>
public class AdminService(
    IAdminRepository repo,
    IValidator<UpdateCouponRequest> updateCouponValidator,
    IValidator<ForceCancelOrderRequest> forceCancelValidator,
    IValidator<ManualRefundRequest> manualRefundValidator)
    : IAdminService
{
    private static readonly JsonSerializerOptions JsonOpts = new() { WriteIndented = false };

    private Task LogAsync(string table, int recordId, string verb, object? payload, int adminUserId, string? ip)
        => repo.WriteAuditAsync(
            tableName: table,
            recordId:  recordId,
            action:    "UPDATE",   // table CHECK constrains to INSERT/UPDATE/DELETE
            oldValues: null,
            newValues: JsonSerializer.Serialize(new { verb, data = payload }, JsonOpts),
            changedBy: adminUserId,
            ipAddress: ip);

    // ── Reads ────────────────────────────────────────────────────────────────

    public Task<AdminStatsDto> GetDashboardStatsAsync() => repo.GetDashboardStatsAsync();

    public Task<(List<AdminSellerDto> Items, int Total)> GetSellersAsync(int page, int pageSize, byte? approvalStatus, string? search)
        => repo.GetSellersAsync(page, pageSize, approvalStatus, search);

    public Task<(List<AdminProductDto> Items, int Total)> GetProductsAsync(int page, int pageSize, byte? approvalStatus, string? search)
        => repo.GetProductsAsync(page, pageSize, approvalStatus, search);

    public Task<(List<AdminProductDto> Items, int Total)> GetProductModerationQueueAsync(int page, int pageSize)
        => repo.GetProductModerationQueueAsync(page, pageSize);

    public Task<(List<AdminUserDto> Items, int Total)> GetUsersAsync(int page, int pageSize, byte? roleId, string? search)
        => repo.GetUsersAsync(page, pageSize, roleId, search);

    public Task<(List<AdminOrderDto> Items, int Total)> GetOrdersAsync(int page, int pageSize, byte? status, string? search, byte? lineStatusFilter = null, byte? paymentStatusFilter = null)
        => repo.GetOrdersAsync(page, pageSize, status, search, lineStatusFilter, paymentStatusFilter);

    public Task<(List<AdminReviewDto> Items, int Total)> GetReviewsAsync(int page, int pageSize, bool? isApproved)
        => repo.GetReviewsAsync(page, pageSize, isApproved);

    public Task<AdminSellerScoreDto> GetSellerScoreAsync(int sellerId, DateTime? from, DateTime? to)
        => repo.GetSellerScoreAsync(sellerId, from, to);

    public Task<(List<AdminAuditEntryDto> Items, int Total)> QueryAuditAsync(string? tableName, int? recordId, int? changedBy, DateTime? from, DateTime? to, int page, int pageSize)
        => repo.QueryAuditAsync(tableName, recordId, changedBy, from, to, page, pageSize);

    // ── Writes ───────────────────────────────────────────────────────────────

    public async Task ApproveSellerAsync(int sellerId, int adminUserId, string? ip)
    {
        await repo.ApproveSellerAsync(sellerId, adminUserId);
        await LogAsync("Sellers", sellerId, "APPROVE_SELLER", null, adminUserId, ip);
    }

    public async Task RejectSellerAsync(int sellerId, int adminUserId, string? reason, string? ip)
    {
        await repo.RejectSellerAsync(sellerId, adminUserId, reason);
        await LogAsync("Sellers", sellerId, "REJECT_SELLER", new { reason }, adminUserId, ip);
    }

    public async Task SuspendSellerAsync(int sellerId, int adminUserId, string? ip)
    {
        await repo.SuspendSellerAsync(sellerId, adminUserId);
        await LogAsync("Sellers", sellerId, "SUSPEND_SELLER", null, adminUserId, ip);
    }

    public async Task ApproveProductAsync(int productId, int adminUserId, string? ip)
    {
        await repo.ApproveProductAsync(productId, adminUserId);
        await LogAsync("Products", productId, "APPROVE_PRODUCT", null, adminUserId, ip);
    }

    public async Task RejectProductAsync(int productId, int adminUserId, string? reason, string? ip)
    {
        await repo.RejectProductAsync(productId, adminUserId, reason);
        await LogAsync("Products", productId, "REJECT_PRODUCT", new { reason }, adminUserId, ip);
    }

    public async Task ApproveReviewAsync(int reviewId, int adminUserId, string? ip)
    {
        await repo.ApproveReviewAsync(reviewId, adminUserId);
        await LogAsync("Reviews", reviewId, "APPROVE_REVIEW", null, adminUserId, ip);
    }

    public async Task SuspendUserAsync(int userId, int adminUserId, string? reason, string? ip)
    {
        await repo.SuspendUserAsync(userId, adminUserId, reason);
        await LogAsync("Users", userId, "SUSPEND_USER", new { reason }, adminUserId, ip);
    }

    public async Task ActivateUserAsync(int userId, int adminUserId, string? ip)
    {
        await repo.ActivateUserAsync(userId, adminUserId);
        await LogAsync("Users", userId, "ACTIVATE_USER", null, adminUserId, ip);
    }

    public async Task SoftDeleteUserAsync(int userId, int adminUserId, string? ip)
    {
        await repo.SoftDeleteUserAsync(userId, adminUserId);
        await LogAsync("Users", userId, "SOFT_DELETE_USER", null, adminUserId, ip);
    }

    public async Task ForceCancelOrderAsync(int orderId, int adminUserId, ForceCancelOrderRequest req, string? ip)
    {
        await forceCancelValidator.ValidateAndThrowAsync(req);
        await repo.ForceCancelOrderAsync(orderId, adminUserId, req.Reason);
        await LogAsync("Orders", orderId, "FORCE_CANCEL_ORDER", new { req.Reason }, adminUserId, ip);
    }

    public async Task ManualRefundOrderAsync(int orderId, int adminUserId, ManualRefundRequest req, string? ip)
    {
        await manualRefundValidator.ValidateAndThrowAsync(req);
        await repo.ManualRefundOrderAsync(orderId, adminUserId, req.RefundAmount, req.Reason, req.GatewayRef);
        await LogAsync("Orders", orderId, "MANUAL_REFUND_ORDER",
            new { req.RefundAmount, req.Reason, req.GatewayRef }, adminUserId, ip);
    }

    public async Task UpdateCouponAsync(int couponId, UpdateCouponRequest req, int adminUserId, string? ip)
    {
        await updateCouponValidator.ValidateAndThrowAsync(req);
        await repo.UpdateCouponAsync(couponId, req, adminUserId);
        await LogAsync("Coupons", couponId, "UPDATE_COUPON",
            new { req.CouponCode, req.DiscountValue, req.StartDate, req.EndDate }, adminUserId, ip);
    }

    public async Task DeleteCouponAsync(int couponId, int adminUserId, string? ip)
    {
        await repo.DeleteCouponAsync(couponId, adminUserId);
        await LogAsync("Coupons", couponId, "DELETE_COUPON", null, adminUserId, ip);
    }
}
