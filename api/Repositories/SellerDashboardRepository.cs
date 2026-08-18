using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface ISellerDashboardRepository
{
    Task<SellerDashboardDto?> GetDashboardStatsAsync(int sellerId);
    Task<SellerAnalyticsDto?> GetAnalyticsAsync(int sellerId, DateTime fromDate, DateTime toDate);
    Task AggregateAnalyticsAsync(DateTime analyticsDate);
}

public class SellerDashboardRepository(IConfiguration config) : ISellerDashboardRepository
{
    private SqlConnection Conn() =>
        new(config.GetConnectionString("ShopNShop"));

    public async Task<SellerDashboardDto?> GetDashboardStatsAsync(int sellerId)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerDashboardDto>(
            "sp_SellerGetDashboard",
            new { SellerId = sellerId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<SellerAnalyticsDto?> GetAnalyticsAsync(int sellerId, DateTime fromDate, DateTime toDate)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerAnalyticsDto>(
            "usp_Seller_Dashboard_GetAnalytics",
            new { SellerId = sellerId, FromDate = fromDate, ToDate = toDate },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task AggregateAnalyticsAsync(DateTime analyticsDate)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Seller_Analytics_Aggregate",
            new { AnalyticsDate = analyticsDate },
            commandType: System.Data.CommandType.StoredProcedure);
    }
}
