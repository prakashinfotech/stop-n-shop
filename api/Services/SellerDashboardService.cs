using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface ISellerDashboardService
{
    Task<SellerDashboardDto?> GetDashboardAsync(int sellerId);
    Task<SellerAnalyticsDto?> GetAnalyticsAsync(int sellerId, DateTime fromDate, DateTime toDate);
    Task AggregateAnalyticsAsync(DateTime analyticsDate);
}

public class SellerDashboardService(ISellerDashboardRepository repo) : ISellerDashboardService
{
    public Task<SellerDashboardDto?> GetDashboardAsync(int sellerId) =>
        repo.GetDashboardStatsAsync(sellerId);

    public Task<SellerAnalyticsDto?> GetAnalyticsAsync(int sellerId, DateTime fromDate, DateTime toDate) =>
        repo.GetAnalyticsAsync(sellerId, fromDate, toDate);

    public Task AggregateAnalyticsAsync(DateTime analyticsDate) =>
        repo.AggregateAnalyticsAsync(analyticsDate);
}
