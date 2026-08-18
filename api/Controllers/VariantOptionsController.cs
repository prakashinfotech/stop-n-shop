using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

[ApiController]
[Produces("application/json")]
public class VariantOptionsController(IVariantLibraryService service) : ControllerBase
{
    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// Public read used by seller wizard + PDP variant pickers.
    /// Returns the active option library for a subcategory.
    /// </summary>
    [HttpGet("api/catalog/subcategories/{subCategoryId:int}/variant-options")]
    [AllowAnonymous]
    public async Task<IActionResult> GetForSubCategory(int subCategoryId)
    {
        var rows = await service.GetForSellerAsync(subCategoryId, productId: null);
        return Ok(ApiResponse<List<SellerVariantOptionDto>>.Ok(rows));
    }

    /// <summary>
    /// Seller-scoped read: returns the subcategory library plus per-product disable flags.
    /// </summary>
    [HttpGet("api/seller/products/{productId:int}/variant-options")]
    [Authorize(Roles = "Seller")]
    public async Task<IActionResult> GetForSellerProduct(int productId, [FromQuery] int subCategoryId)
    {
        var rows = await service.GetForSellerAsync(subCategoryId, productId);
        return Ok(ApiResponse<List<SellerVariantOptionDto>>.Ok(rows));
    }

    /// <summary>
    /// Seller updates the disabled-option set for one of their products.
    /// </summary>
    [HttpPut("api/seller/products/{productId:int}/variant-options/disabled")]
    [Authorize(Roles = "Seller")]
    public async Task<IActionResult> SetDisabled(int productId, [FromBody] SetDisabledOptionsRequest req)
    {
        try
        {
            await service.SetDisabledOptionsAsync(productId, CurrentUserId, req, CurrentUserId);
            return Ok(ApiResponse<object>.Ok(null!, "Saved."));
        }
        catch (SqlException ex) when (ex.Number == 50221) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }
}
