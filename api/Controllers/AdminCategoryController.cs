using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

[ApiController]
[Route("api/admin/categories")]
[Authorize(Roles = "Admin")]
[Produces("application/json")]
public class AdminCategoryController(IAdminCategoryService service) : ControllerBase
{
    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private string? ClientIp  => HttpContext?.Connection.RemoteIpAddress?.ToString();

    // ── Tree ──────────────────────────────────────────────────────────────────

    /// <summary>Full category + subcategory tree for the admin editor.</summary>
    [HttpGet("tree")]
    public async Task<IActionResult> GetTree([FromQuery] bool includeInactive = true)
    {
        var tree = await service.GetTreeAsync(includeInactive);
        return Ok(ApiResponse<AdminMegaMenuTreeDto>.Ok(tree));
    }

    // ── Categories ────────────────────────────────────────────────────────────

    [HttpPost]
    public async Task<IActionResult> UpsertCategory([FromBody] AdminCategoryUpsertRequest req)
    {
        try
        {
            var id = await service.UpsertCategoryAsync(req, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(new { CategoryId = id }));
        }
        catch (SqlException ex) when (ex.Number == 50200) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("{id:int}/toggle")]
    public async Task<IActionResult> ToggleCategory(int id, [FromBody] ToggleVisibilityRequest req)
    {
        try
        {
            await service.ToggleCategoryVisibilityAsync(id, req, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(null!, "Updated."));
        }
        catch (SqlException ex) when (ex.Number == 50200) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("reorder")]
    public async Task<IActionResult> ReorderCategories([FromBody] CategoryReorderRequest req)
    {
        await service.ReorderCategoriesAsync(req, CurrentUserId, ClientIp);
        return Ok(ApiResponse<object>.Ok(null!, "Reordered."));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> DeleteCategory(int id)
    {
        try
        {
            await service.DeleteCategoryAsync(id, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(null!, "Category deleted."));
        }
        catch (SqlException ex) when (ex.Number is 50200 or 50201) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    // ── Subcategories ─────────────────────────────────────────────────────────

    [HttpPost("subcategories")]
    public async Task<IActionResult> UpsertSubCategory([FromBody] AdminSubCategoryUpsertRequest req)
    {
        try
        {
            var id = await service.UpsertSubCategoryAsync(req, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(new { SubCategoryId = id }));
        }
        catch (SqlException ex) when (ex.Number is 50202 or 50203) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("subcategories/{id:int}/toggle")]
    public async Task<IActionResult> ToggleSubCategory(int id, [FromBody] ToggleVisibilityRequest req)
    {
        try
        {
            await service.ToggleSubCategoryVisibilityAsync(id, req, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(null!, "Updated."));
        }
        catch (SqlException ex) when (ex.Number == 50203) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    [HttpPatch("subcategories/reorder")]
    public async Task<IActionResult> ReorderSubCategories([FromBody] SubCategoryReorderRequest req)
    {
        await service.ReorderSubCategoriesAsync(req, CurrentUserId, ClientIp);
        return Ok(ApiResponse<object>.Ok(null!, "Reordered."));
    }

    [HttpDelete("subcategories/{id:int}")]
    public async Task<IActionResult> DeleteSubCategory(int id)
    {
        try
        {
            await service.DeleteSubCategoryAsync(id, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(null!, "Subcategory deleted."));
        }
        catch (SqlException ex) when (ex.Number is 50203 or 50204) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    /// <summary>Updates the per-subcategory product-form rules (image angles, size scale, gender + dimensions flags).</summary>
    [HttpPatch("subcategories/{id:int}/form-rules")]
    public async Task<IActionResult> UpdateFormRules(int id, [FromBody] UpdateFormRulesRequest req)
    {
        try
        {
            await service.UpdateSubCategoryFormRulesAsync(id, req, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(null!, "Form rules updated."));
        }
        catch (SqlException ex) when (ex.Number == 50203) { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }
}
