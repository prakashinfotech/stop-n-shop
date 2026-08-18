using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Buyer wallet — balance and transaction history.</summary>
[ApiController]
[Route("api/wallet")]
[Produces("application/json")]
public class WalletController(IWalletService svc) : ControllerBase
{
    /// <summary>Claim the one-time ₹500 welcome bonus. No-op if already claimed.</summary>
    [HttpPost("welcome-bonus")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<WelcomeBonusResult>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ClaimWelcomeBonus()
    {
        var userId = GetUserId();
        if (userId == 0) return Unauthorized(ApiResponse<object>.Fail("Sign in to claim your welcome bonus."));
        var result = await svc.ClaimWelcomeBonusAsync(userId);
        return Ok(ApiResponse<WelcomeBonusResult>.Ok(result, result.Message));
    }

    /// <summary>Dismiss the welcome-bonus prompt without crediting. Suppresses the popup on future logins.</summary>
    [HttpPost("welcome-bonus/dismiss")]
    [Authorize]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    public async Task<IActionResult> DismissWelcomeBonus()
    {
        var userId = GetUserId();
        if (userId == 0) return Unauthorized(ApiResponse<object>.Fail("Sign in to dismiss."));
        await svc.DismissWelcomeBonusAsync(userId);
        return Ok(ApiResponse<object>.Ok(null!, "Welcome bonus dismissed."));
    }

    /// <summary>Get wallet balance and recent transactions (first page).</summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<WalletPageDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetWallet(
        [FromQuery] int page     = 1,
        [FromQuery] int pageSize = 20)
    {
        var userId = GetUserId();
        if (userId == 0)
            return Ok(ApiResponse<WalletPageDto>.Ok(new WalletPageDto()));

        var result = await svc.GetWalletPageAsync(userId, page, pageSize);
        return Ok(ApiResponse<WalletPageDto>.Ok(result));
    }

    private int GetUserId()
    {
        var claim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.TryParse(claim, out var id) ? id : 0;
    }
}
