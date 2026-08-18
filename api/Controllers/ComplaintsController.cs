using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>
/// Customer complaint / support-ticket surface. Tickets are created from the
/// Aria assistant (or directly) and reviewed by admin. A dedicated tech-support
/// role will read the same endpoints later.
/// </summary>
[ApiController]
[Produces("application/json")]
public class ComplaintsController(IComplaintService svc) : ControllerBase
{
    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // ── Buyer ────────────────────────────────────────────────────────────────

    /// <summary>Buyer-side: file a new complaint (Aria or direct UI).</summary>
    [HttpPost("api/complaints")]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] CreateComplaintRequest req)
    {
        if (req is null) return BadRequest(ApiResponse<object>.Fail("Invalid payload."));
        try
        {
            var id = await svc.CreateAsync(CurrentUserId, req);
            return Ok(ApiResponse<object>.Ok(new { complaintId = id }, "Complaint received."));
        }
        catch (SqlException ex) when (ex.Number is 50400 or 50401)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Buyer-side: list my complaints (most recent first).</summary>
    [HttpGet("api/complaints/mine")]
    [Authorize]
    public async Task<IActionResult> GetMine([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var (items, total) = await svc.GetByUserAsync(CurrentUserId, page, pageSize);
        return Ok(ApiResponse<object>.Ok(new { items, totalCount = total, page, pageSize }));
    }

    // ── Admin ────────────────────────────────────────────────────────────────

    /// <summary>Admin: list all complaints with optional status/category filters.</summary>
    [HttpGet("api/admin/complaints")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> AdminList(
        [FromQuery] byte?   status   = null,
        [FromQuery] string? category = null,
        [FromQuery] string? search   = null,
        [FromQuery] int     page     = 1,
        [FromQuery] int     pageSize = 20)
    {
        var (items, total) = await svc.AdminGetAllAsync(status, category, search, page, pageSize);
        return Ok(ApiResponse<object>.Ok(new { items, totalCount = total, page, pageSize }));
    }

    /// <summary>Admin: change status (Open / InProgress / Resolved / Closed) and optionally add a note.</summary>
    [HttpPatch("api/admin/complaints/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> AdminUpdate(int id, [FromBody] UpdateComplaintStatusRequest req)
    {
        try
        {
            await svc.UpdateStatusAsync(id, req.Status, req.AdminNote, CurrentUserId);
            return Ok(ApiResponse<object>.Ok(null!, "Complaint updated."));
        }
        catch (SqlException ex) when (ex.Number is 50410 or 50411)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }
}
