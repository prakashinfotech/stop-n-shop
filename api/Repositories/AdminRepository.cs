using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IAdminRepository
{
    Task<AdminStatsDto> GetDashboardStatsAsync();
    Task<(List<AdminSellerDto> Items, int Total)> GetSellersAsync(int page, int pageSize, byte? approvalStatus, string? search);
    Task<(List<AdminProductDto> Items, int Total)> GetProductsAsync(int page, int pageSize, byte? approvalStatus, string? search);
    Task<(List<AdminUserDto> Items, int Total)> GetUsersAsync(int page, int pageSize, byte? roleId, string? search);
    Task<(List<AdminOrderDto> Items, int Total)> GetOrdersAsync(int page, int pageSize, byte? status, string? search, byte? lineStatusFilter = null, byte? paymentStatusFilter = null);
    Task<(List<AdminReviewDto> Items, int Total)> GetReviewsAsync(int page, int pageSize, bool? isApproved);

    Task ApproveSellerAsync(int sellerId, int adminUserId);
    Task RejectSellerAsync(int sellerId, int adminUserId, string? reason);
    Task SuspendSellerAsync(int sellerId, int adminUserId);
    Task ApproveProductAsync(int productId, int adminUserId);
    Task RejectProductAsync(int productId, int adminUserId, string? reason);
    Task ApproveReviewAsync(int reviewId, int adminUserId);

    // Phase 1 additions
    Task SuspendUserAsync(int userId, int adminUserId, string? reason);
    Task ActivateUserAsync(int userId, int adminUserId);
    Task SoftDeleteUserAsync(int userId, int adminUserId);
    Task<AdminSellerScoreDto> GetSellerScoreAsync(int sellerId, DateTime? from, DateTime? to);
    Task<(List<AdminProductDto> Items, int Total)> GetProductModerationQueueAsync(int page, int pageSize);
    Task ForceCancelOrderAsync(int orderId, int adminUserId, string reason);
    Task ManualRefundOrderAsync(int orderId, int adminUserId, decimal refundAmount, string reason, string? gatewayRef);
    Task UpdateCouponAsync(int couponId, UpdateCouponRequest req, int adminUserId);
    Task DeleteCouponAsync(int couponId, int adminUserId);
    Task<long> WriteAuditAsync(string tableName, int recordId, string action, string? oldValues, string? newValues, int changedBy, string? ipAddress);
    Task<(List<AdminAuditEntryDto> Items, int Total)> QueryAuditAsync(string? tableName, int? recordId, int? changedBy, DateTime? from, DateTime? to, int page, int pageSize);
}

public class AdminRepository(IConfiguration config) : IAdminRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<AdminStatsDto> GetDashboardStatsAsync()
    {
        using var db = Conn();
        using var multi = await db.QueryMultipleAsync(
            "usp_Admin_Dashboard_GetStats",
            new { FromDate = (DateTime?)null, ToDate = (DateTime?)null },
            commandType: System.Data.CommandType.StoredProcedure);

        return await multi.ReadFirstAsync<AdminStatsDto>();
    }

    private sealed class SellerRow : AdminSellerDto { public int TotalCount { get; set; } }
    public async Task<(List<AdminSellerDto> Items, int Total)> GetSellersAsync(int page, int pageSize, byte? approvalStatus, string? search)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<SellerRow>(
            "usp_Admin_Seller_GetAll",
            new { ApprovalStatus = approvalStatus, SearchTerm = search, PageNumber = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<AdminSellerDto>().ToList(), total);
    }

    private sealed class ProductRow : AdminProductDto { public int TotalCount { get; set; } }
    public async Task<(List<AdminProductDto> Items, int Total)> GetProductsAsync(int page, int pageSize, byte? approvalStatus, string? search)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<ProductRow>(
            "usp_Admin_Product_GetAll",
            new { ApprovalStatus = approvalStatus, SearchTerm = search, PageNumber = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<AdminProductDto>().ToList(), total);
    }

    private sealed class UserRow
    {
        public int UserId { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public string? Mobile { get; set; }
        public string? RoleName { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
        public int TotalCount { get; set; }
    }
    public async Task<(List<AdminUserDto> Items, int Total)> GetUsersAsync(int page, int pageSize, byte? roleId, string? search)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<UserRow>(
            "usp_Admin_User_GetAll",
            new { RoleId = roleId, SearchTerm = search, IsActive = (bool?)null, PageNumber = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        var items = rows.Select(r => new AdminUserDto
        {
            Id        = r.UserId,
            FirstName = r.FirstName,
            LastName  = r.LastName,
            Email     = r.Email,
            Mobile    = r.Mobile,
            Role      = r.RoleName ?? string.Empty,
            IsActive  = r.IsActive,
            CreatedAt = r.CreatedAt,
        }).ToList();
        return (items, total);
    }

    private sealed class OrderRow
    {
        public int OrderId { get; set; }
        public string OrderNumber { get; set; } = string.Empty;
        public byte OrderStatus { get; set; }
        public decimal TotalAmount { get; set; }
        public byte PaymentMode { get; set; }
        public byte PaymentStatus { get; set; }
        public DateTime OrderDate { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public int ItemCount { get; set; }
        public int TotalCount { get; set; }
    }
    public async Task<(List<AdminOrderDto> Items, int Total)> GetOrdersAsync(int page, int pageSize, byte? status, string? search, byte? lineStatusFilter = null, byte? paymentStatusFilter = null)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<OrderRow>(
            "usp_Admin_Order_GetAll",
            new
            {
                OrderStatus         = status,
                FromDate            = (DateTime?)null,
                ToDate              = (DateTime?)null,
                SearchTerm          = search,
                LineStatusFilter    = lineStatusFilter,
                PaymentStatusFilter = paymentStatusFilter,
                PageNumber          = page,
                PageSize            = pageSize,
            },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        var items = rows.Select(r => new AdminOrderDto
        {
            Id           = r.OrderId,
            OrderNumber  = r.OrderNumber,
            CustomerName = $"{r.FirstName} {r.LastName}".Trim(),
            SellerName   = null,
            Status       = MapOrderStatus(r.OrderStatus),
            FinalAmount  = r.TotalAmount,
            CreatedAt    = r.OrderDate,
        }).ToList();
        return (items, total);
    }

    private sealed class ReviewRow : AdminReviewDto { public int TotalCount { get; set; } }
    public async Task<(List<AdminReviewDto> Items, int Total)> GetReviewsAsync(int page, int pageSize, bool? isApproved)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<ReviewRow>(
            "usp_Admin_Review_GetAll",
            new { IsApproved = isApproved, PageNumber = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<AdminReviewDto>().ToList(), total);
    }

    public async Task ApproveSellerAsync(int sellerId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_Seller_Approve",
            new { SellerId = sellerId, UpdatedBy = adminUserId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task RejectSellerAsync(int sellerId, int adminUserId, string? reason)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_Seller_Reject",
            new { SellerId = sellerId, UpdatedBy = adminUserId, RejectReason = reason },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task SuspendSellerAsync(int sellerId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_Seller_Suspend",
            new { SellerId = sellerId, UpdatedBy = adminUserId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task ApproveProductAsync(int productId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_Product_Approve",
            new { ProductId = productId, UpdatedBy = adminUserId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task RejectProductAsync(int productId, int adminUserId, string? reason)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_Product_Reject",
            new { ProductId = productId, UpdatedBy = adminUserId, RejectReason = reason },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task ApproveReviewAsync(int reviewId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Engagement_Review_Approve",
            new { ReviewId = reviewId, UpdatedBy = adminUserId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    private static string MapOrderStatus(byte raw) => raw switch
    {
        1 => "PLACED",     2 => "CONFIRMED", 3 => "PACKED",     4 => "DISPATCHED",
        9 => "OUT_FOR_DELIVERY",
        5 => "DELIVERED",  6 => "CANCELLED", 7 => "RETURNED",   8 => "REJECTED",
        _ => raw.ToString()
    };

    // ── Phase 1 additions ─────────────────────────────────────────────────────

    public async Task SuspendUserAsync(int userId, int adminUserId, string? reason)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_User_Suspend",
            new { UserId = userId, AdminUserId = adminUserId, Reason = reason },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task ActivateUserAsync(int userId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_User_Activate",
            new { UserId = userId, AdminUserId = adminUserId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task SoftDeleteUserAsync(int userId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_User_SoftDelete",
            new { UserId = userId, AdminUserId = adminUserId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<AdminSellerScoreDto> GetSellerScoreAsync(int sellerId, DateTime? from, DateTime? to)
    {
        using var db = Conn();
        return await db.QueryFirstAsync<AdminSellerScoreDto>(
            "usp_Admin_Seller_ScoreGet",
            new { SellerId = sellerId, FromDate = from, ToDate = to },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<(List<AdminProductDto> Items, int Total)> GetProductModerationQueueAsync(int page, int pageSize)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<ProductRow>(
            "usp_Admin_Product_ModerationQueue",
            new { PageNumber = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<AdminProductDto>().ToList(), total);
    }

    public async Task ForceCancelOrderAsync(int orderId, int adminUserId, string reason)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_Order_ForceCancel",
            new { OrderId = orderId, AdminUserId = adminUserId, Reason = reason },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task ManualRefundOrderAsync(int orderId, int adminUserId, decimal refundAmount, string reason, string? gatewayRef)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_Order_ManualRefund",
            new
            {
                OrderId      = orderId,
                AdminUserId  = adminUserId,
                RefundAmount = refundAmount,
                Reason       = reason,
                GatewayRef   = gatewayRef,
            },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task UpdateCouponAsync(int couponId, UpdateCouponRequest req, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_Coupon_Update",
            new
            {
                CouponId          = couponId,
                req.CouponCode,
                req.OfferName,
                req.OfferType,
                req.DiscountValue,
                req.MinOrderValue,
                req.MaxDiscountCap,
                req.StartDate,
                req.EndDate,
                req.ApplicableOn,
                req.EntityId,
                req.UsageLimitPerUser,
                AdminUserId       = adminUserId,
            },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task DeleteCouponAsync(int couponId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync("usp_Admin_Coupon_Delete",
            new { CouponId = couponId, AdminUserId = adminUserId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<long> WriteAuditAsync(string tableName, int recordId, string action, string? oldValues, string? newValues, int changedBy, string? ipAddress)
    {
        using var db = Conn();
        return await db.ExecuteScalarAsync<long>(
            "usp_Admin_AuditTrail_Log",
            new
            {
                TableName = tableName,
                RecordId  = recordId,
                Action    = action,
                OldValues = oldValues,
                NewValues = newValues,
                ChangedBy = changedBy,
                IpAddress = ipAddress,
            },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    private sealed class AuditRow : AdminAuditEntryDto { public int TotalCount { get; set; } }
    public async Task<(List<AdminAuditEntryDto> Items, int Total)> QueryAuditAsync(
        string? tableName, int? recordId, int? changedBy, DateTime? from, DateTime? to, int page, int pageSize)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<AuditRow>(
            "usp_Admin_AuditTrail_Query",
            new
            {
                TableName  = tableName,
                RecordId   = recordId,
                ChangedBy  = changedBy,
                FromDate   = from,
                ToDate     = to,
                PageNumber = page,
                PageSize   = pageSize,
            },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<AdminAuditEntryDto>().ToList(), total);
    }
}
