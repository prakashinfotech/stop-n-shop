using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface ICouponRepository
{
    Task<CouponValidateResult> ValidateAsync(string couponCode, int userId, decimal orderSubTotal);
    Task<(List<AdminCouponDto> Items, int Total)> GetAllAsync(int page, int pageSize);
    Task<int> CreateAsync(CreateCouponRequest req, int adminUserId);
    Task ToggleAsync(int couponId, bool isActive, int adminUserId);
    Task<List<AvailableCouponDto>> GetAvailableAsync(int? userId);
}

public class CouponRepository(IConfiguration config) : ICouponRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<CouponValidateResult> ValidateAsync(string couponCode, int userId, decimal orderSubTotal)
    {
        using var db = Conn();
        var row = await db.QueryFirstOrDefaultAsync(
            "usp_Commerce_Coupon_Validate",
            new { CouponCode = couponCode, UserId = userId, OrderSubTotal = orderSubTotal },
            commandType: System.Data.CommandType.StoredProcedure);

        if (row is null)
            return new CouponValidateResult { IsValid = false, Message = "Invalid coupon code." };

        // SP returns: CouponId, CouponCode, DiscountAmount, OfferType, IsValid.
        // Use dictionary-style access so missing optional columns don't throw on dynamic.
        var dict = (IDictionary<string, object>)row;
        bool isValid = dict.TryGetValue("IsValid", out var iv) && iv is not null &&
                       (iv is bool b ? b : Convert.ToInt32(iv) == 1);
        decimal discount = isValid && dict.TryGetValue("DiscountAmount", out var da) && da is not null
            ? Convert.ToDecimal(da) : 0m;
        string? message      = dict.TryGetValue("Message",      out var msg) ? msg as string : null;
        string? discountType = dict.TryGetValue("DiscountType", out var dt)  ? dt  as string : null;

        return new CouponValidateResult
        {
            IsValid        = isValid,
            DiscountAmount = discount,
            Message        = message ?? (isValid ? "Coupon applied successfully." : "Invalid coupon code."),
            CouponCode     = isValid ? couponCode : null,
            DiscountType   = discountType,
        };
    }

    private sealed class AdminCouponRow : AdminCouponDto
    {
        public int TotalCount { get; set; }
    }

    public async Task<(List<AdminCouponDto> Items, int Total)> GetAllAsync(int page, int pageSize)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<AdminCouponRow>(
            "usp_Admin_Coupon_GetAll",
            new { Page = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();

        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<AdminCouponDto>().ToList(), total);
    }

    public async Task<int> CreateAsync(CreateCouponRequest req, int adminUserId)
    {
        using var db = Conn();
        var id = await db.QuerySingleAsync<int>(
            "usp_Admin_Coupon_Create",
            new
            {
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
                AdminUserId = adminUserId
            },
            commandType: System.Data.CommandType.StoredProcedure);
        return id;
    }

    public async Task ToggleAsync(int couponId, bool isActive, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_Coupon_Toggle",
            new { CouponId = couponId, IsActive = isActive, AdminUserId = adminUserId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<List<AvailableCouponDto>> GetAvailableAsync(int? userId)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<AvailableCouponDto>(
            "usp_Customer_Coupon_GetAvailable",
            new { UserId = userId },
            commandType: System.Data.CommandType.StoredProcedure);
        return rows.ToList();
    }
}
