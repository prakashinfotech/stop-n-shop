using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Seller dashboard — statistics and KPIs.</summary>
[ApiController]
[Route("api/seller/dashboard")]
[Produces("application/json")]
[Authorize(Roles = "Seller")]
public class SellerDashboardController(ISellerDashboardService svc) : ControllerBase
{
    /// <summary>Get dashboard statistics for the seller.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<SellerDashboardDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetDashboard()
    {
        var sellerId = GetSellerId();
        var stats = await svc.GetDashboardAsync(sellerId);

        if (stats is null)
            return Ok(ApiResponse<SellerDashboardDto>.Ok(
                new SellerDashboardDto(),
                "Dashboard data retrieved."));

        return Ok(ApiResponse<SellerDashboardDto>.Ok(stats));
    }

    private int GetSellerId() =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
