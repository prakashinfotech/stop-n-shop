using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Seller onboarding — business registration and profile management.</summary>
[ApiController]
[Route("api/seller")]
[Produces("application/json")]
[Authorize(Roles = "Seller")]
public class SellerController(ISellerAuthService svc) : ControllerBase
{
    /// <summary>Register seller business details (GST, PAN, bank account, address).</summary>
    /// <remarks>Call once after account creation to complete business registration.</remarks>
    [HttpPost("onboarding")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] SellerRegisterRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.BusinessName))
            return BadRequest(ApiResponse<object>.Fail("Business name is required."));
        if (string.IsNullOrWhiteSpace(req.GstNumber))
            return BadRequest(ApiResponse<object>.Fail("GST number is required."));
        if (string.IsNullOrWhiteSpace(req.PanNumber))
            return BadRequest(ApiResponse<object>.Fail("PAN number is required."));
        if (string.IsNullOrWhiteSpace(req.BankAccountNumber))
            return BadRequest(ApiResponse<object>.Fail("Bank account number is required."));
        if (string.IsNullOrWhiteSpace(req.BankIfscCode))
            return BadRequest(ApiResponse<object>.Fail("Bank IFSC code is required."));
        if (string.IsNullOrWhiteSpace(req.BankName))
            return BadRequest(ApiResponse<object>.Fail("Bank name is required."));

        await svc.RegisterAsync(GetSellerId(), req);
        return Ok(ApiResponse<object>.Ok(null!, "Business registration completed successfully."));
    }

    /// <summary>Get the authenticated seller's profile.</summary>
    [HttpGet("profile")]
    [ProducesResponseType(typeof(ApiResponse<SellerProfileDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProfile()
    {
        var profile = await svc.GetProfileByUserIdAsync(GetSellerId());
        if (profile is null)
            return NotFound(ApiResponse<object>.Fail("Seller profile not found."));

        return Ok(ApiResponse<SellerProfileDto>.Ok(profile));
    }

    /// <summary>Update seller business name and bank details.</summary>
    [HttpPut("profile")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateSellerBankRequest req)
    {
        var sellerId = GetSellerId();
        await svc.UpdateBankProfileAsync(sellerId, req, updatedBy: sellerId);
        return Ok(ApiResponse<object>.Ok(null!, "Profile updated successfully."));
    }

    private int GetSellerId() =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
