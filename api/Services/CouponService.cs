using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface ICouponService
{
    Task<CouponValidateResult> ValidateAsync(string couponCode, int userId, decimal cartTotal);
    Task<(List<AdminCouponDto> Items, int Total)> GetAllAsync(int page, int pageSize);
    Task<int> CreateAsync(CreateCouponRequest req, int adminUserId);
    Task ToggleAsync(int couponId, bool isActive, int adminUserId);
    Task<List<AvailableCouponDto>> GetAvailableAsync(int? userId);
}

public class CouponService(ICouponRepository repo) : ICouponService
{
    public Task<CouponValidateResult> ValidateAsync(string couponCode, int userId, decimal cartTotal)
        => repo.ValidateAsync(couponCode, userId, cartTotal);

    public Task<(List<AdminCouponDto> Items, int Total)> GetAllAsync(int page, int pageSize)
        => repo.GetAllAsync(page, pageSize);

    public Task<int> CreateAsync(CreateCouponRequest req, int adminUserId)
        => repo.CreateAsync(req, adminUserId);

    public Task ToggleAsync(int couponId, bool isActive, int adminUserId)
        => repo.ToggleAsync(couponId, isActive, adminUserId);

    public Task<List<AvailableCouponDto>> GetAvailableAsync(int? userId)
        => repo.GetAvailableAsync(userId);
}
