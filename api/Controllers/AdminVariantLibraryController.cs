using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

[ApiController]
[Route("api/admin/variant-library")]
[Authorize(Roles = "Admin")]
[Produces("application/json")]
public class AdminVariantLibraryController(IVariantLibraryService service) : ControllerBase
{
    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private string? ClientIp  => HttpContext?.Connection.RemoteIpAddress?.ToString();

    /// <summary>Master list of variant attributes (Size, Color, Material, Pattern, Fit).</summary>
    [HttpGet("attributes")]
    public async Task<IActionResult> GetAttributes()
    {
        var rows = await service.GetAttributesAsync();
        return Ok(ApiResponse<List<VariantAttributeDto>>.Ok(rows));
    }

    /// <summary>Options defined for a single subcategory (grouped by attribute on the client).</summary>
    [HttpGet("subcategories/{subCategoryId:int}/options")]
    public async Task<IActionResult> GetOptions(int subCategoryId)
    {
        var rows = await service.GetAdminOptionsAsync(subCategoryId);
        return Ok(ApiResponse<List<SubCategoryVariantOptionDto>>.Ok(rows));
    }

    [HttpPost("options")]
    public async Task<IActionResult> UpsertOption([FromBody] VariantOptionUpsertRequest req)
    {
        try
        {
            var id = await service.UpsertOptionAsync(req, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(new { OptionId = id }));
        }
        catch (SqlException ex) when (ex.Number == 50220) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("options/{id:int}/toggle")]
    public async Task<IActionResult> ToggleOption(int id, [FromBody] ToggleVisibilityRequest req)
    {
        if (req.IsActive is null) return BadRequest(ApiResponse<object>.Fail("isActive is required."));
        try
        {
            await service.ToggleOptionAsync(id, req.IsActive.Value, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(null!, "Updated."));
        }
        catch (SqlException ex) when (ex.Number == 50220) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpDelete("options/{id:int}")]
    public async Task<IActionResult> DeleteOption(int id)
    {
        try
        {
            await service.DeleteOptionAsync(id, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(null!, "Deleted."));
        }
        catch (SqlException ex) when (ex.Number == 50220) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPut("options/bulk")]
    public async Task<IActionResult> BulkSet([FromBody] VariantOptionBulkSetRequest req)
    {
        await service.BulkSetAsync(req, CurrentUserId, ClientIp);
        return Ok(ApiResponse<object>.Ok(null!, "Library updated."));
    }
}
