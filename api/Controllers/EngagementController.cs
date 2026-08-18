using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>User-scoped engagement endpoints (recently viewed, recent searches, etc.).</summary>
[ApiController]
[Route("api/engagement")]
[Produces("application/json")]
public class EngagementController(IEngagementService engagementService) : ControllerBase
{
    /// <summary>
    /// Returns the signed-in user's last N distinct search terms (newest first).
    /// Used by the home-page "Recent searches" chip row. Returns an empty list
    /// for unauthenticated callers so the UI can render a graceful no-op.
    /// </summary>
    /// <param name="count">Max terms to return (default 6).</param>
    [HttpGet("recent-searches")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<string>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRecentSearches([FromQuery] int count = 6)
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!int.TryParse(userIdClaim, out var userId) || userId <= 0)
            return Ok(ApiResponse<List<string>>.Ok([]));

        var terms = await engagementService.GetRecentSearchesAsync(userId, count);
        return Ok(ApiResponse<List<string>>.Ok(terms));
    }
}
