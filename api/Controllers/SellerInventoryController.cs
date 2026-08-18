using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Seller inventory management — stock tracking and low-stock alerts.</summary>
[ApiController]
[Route("api/seller/inventory")]
[Produces("application/json")]
[Authorize(Roles = "Seller")]
public class SellerInventoryController(ISellerProductService svc) : ControllerBase
{
    /// <summary>Get inventory levels for all seller products.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<SellerInventoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetInventory()
    {
        var sellerId = GetSellerId();
        var inventory = await svc.GetInventoryAsync(sellerId);
        return Ok(ApiResponse<List<SellerInventoryDto>>.Ok(inventory));
    }

    /// <summary>Get low-stock items alert.</summary>
    [HttpGet("low-stock")]
    [ProducesResponseType(typeof(ApiResponse<List<SellerInventoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetLowStockItems()
    {
        var sellerId = GetSellerId();
        var items = await svc.GetLowStockItemsAsync(sellerId);
        return Ok(ApiResponse<List<SellerInventoryDto>>.Ok(items, $"{items.Count} item(s) low on stock."));
    }

    private int GetSellerId() =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
