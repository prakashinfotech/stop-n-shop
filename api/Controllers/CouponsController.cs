using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Coupon / promo-code validation.</summary>
[ApiController]
[Route("api/coupons")]
[Produces("application/json")]
public class CouponsController(ICouponService couponService) : ControllerBase
{
    /// <summary>
    /// Validates a coupon code against the current cart total.
    /// Returns the discount amount if valid.
    /// </summary>
    [HttpPost("validate")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<CouponValidateResult>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Validate([FromBody] CouponValidateRequest req)
    {
        // UserId = 0 when unauthenticated (AllowAnonymous for temp testing)
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var userId = int.TryParse(userIdClaim, out var uid) ? uid : 0;

        var result = await couponService.ValidateAsync(req.CouponCode, userId, req.CartTotal);
        return Ok(ApiResponse<CouponValidateResult>.Ok(result));
    }

    /// <summary>
    /// List of active customer-facing coupons (admin-enabled, within date range,
    /// global-usage cap not yet hit). Per-user usage count is included so the UI
    /// can grey out coupons the signed-in user has already exhausted.
    /// </summary>
    [HttpGet("available")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<List<AvailableCouponDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Available()
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        int? userId = int.TryParse(userIdClaim, out var uid) && uid > 0 ? uid : null;

        var rows = await couponService.GetAvailableAsync(userId);
        return Ok(ApiResponse<List<AvailableCouponDto>>.Ok(rows));
    }
}
