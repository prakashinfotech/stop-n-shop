using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>In-app notifications for the authenticated buyer.</summary>
[ApiController]
[Route("api/notifications")]
[Produces("application/json")]
[AllowAnonymous]
public class NotificationsController(INotificationService svc) : ControllerBase
{
    /// <summary>Get paginated notifications for the current user.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<NotificationsResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(
        [FromQuery] int pageNo   = 1,
        [FromQuery] int pageSize = 20)
    {
        var userId = GetUserId();
        if (userId == 0) return Ok(ApiResponse<NotificationsResultDto>.Ok(new NotificationsResultDto()));

        var result = await svc.GetByUserAsync(userId, pageNo, pageSize);
        return Ok(ApiResponse<NotificationsResultDto>.Ok(result));
    }

    /// <summary>Mark a specific notification as read.</summary>
    [HttpPatch("{id:int}/read")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    public async Task<IActionResult> MarkRead(int id)
    {
        var userId = GetUserId();
        if (userId == 0) return Ok(ApiResponse<object>.Ok(new { }));

        await svc.MarkReadAsync(userId, id);
        return Ok(ApiResponse<object>.Ok(new { }, "Notification marked as read."));
    }

    /// <summary>Mark all notifications as read.</summary>
    [HttpPatch("read-all")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    public async Task<IActionResult> MarkAllRead()
    {
        var userId = GetUserId();
        if (userId == 0) return Ok(ApiResponse<object>.Ok(new { }));

        await svc.MarkReadAsync(userId, null);
        return Ok(ApiResponse<object>.Ok(new { }, "All notifications marked as read."));
    }

    private int GetUserId()
    {
        var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.TryParse(claim, out var id) ? id : 0;
    }
}
