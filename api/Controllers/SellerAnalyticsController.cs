using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Seller analytics — date-range revenue and order KPIs.</summary>
[ApiController]
[Route("api/seller/analytics")]
[Produces("application/json")]
public class SellerAnalyticsController(ISellerDashboardService svc) : ControllerBase
{
    /// <summary>Get seller analytics for a date range.</summary>
    /// <param name="fromDate">Start date (inclusive), format yyyy-MM-dd. Defaults to 30 days ago.</param>
    /// <param name="toDate">End date (inclusive), format yyyy-MM-dd. Defaults to today.</param>
    [HttpGet]
    [Authorize(Roles = "Seller")]
    [ProducesResponseType(typeof(ApiResponse<SellerAnalyticsDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAnalytics(
        [FromQuery] DateTime? fromDate = null,
        [FromQuery] DateTime? toDate   = null)
    {
        var from = (fromDate ?? DateTime.UtcNow.AddDays(-30)).Date;
        var to   = (toDate   ?? DateTime.UtcNow).Date;

        if (from > to)
            return BadRequest(ApiResponse<object>.Fail("fromDate must be on or before toDate."));

        var sellerId = GetSellerId();
        var result   = await svc.GetAnalyticsAsync(sellerId, from, to);

        return Ok(ApiResponse<SellerAnalyticsDto>.Ok(
            result ?? new SellerAnalyticsDto { FromDate = from, ToDate = to }));
    }

    /// <summary>
    /// Trigger analytics aggregation for a specific date.
    /// Intended for cron/scheduler invocation — restricted to Admin role.
    /// </summary>
    [HttpPost("aggregate")]
    [Authorize(Roles = "Admin")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Aggregate([FromBody] AggregateAnalyticsRequest req)
    {
        if (req.AnalyticsDate > DateTime.UtcNow.Date)
            return BadRequest(ApiResponse<object>.Fail("Cannot aggregate analytics for a future date."));

        await svc.AggregateAnalyticsAsync(req.AnalyticsDate.Date);
        return Ok(ApiResponse<object>.Ok(null!, $"Analytics aggregated for {req.AnalyticsDate:yyyy-MM-dd}."));
    }

    private int GetSellerId() =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
