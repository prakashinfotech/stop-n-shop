using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Seller authentication — signup, login, profile management.</summary>
[ApiController]
[Route("api/seller/auth")]
[Produces("application/json")]
public class SellerAuthController(ISellerAuthService svc) : ControllerBase
{
    /// <summary>Register a new seller account — credentials only.</summary>
    /// <param name="req">Email, phone, password, confirm password</param>
    [HttpPost("signup")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<SellerSignupResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Signup([FromBody] SellerSignupRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email))
            return BadRequest(ApiResponse<object>.Fail("Email is required."));
        if (string.IsNullOrWhiteSpace(req.PhoneNumber))
            return BadRequest(ApiResponse<object>.Fail("Phone number is required."));
        if (req.Password != req.ConfirmPassword)
            return BadRequest(ApiResponse<object>.Fail("Passwords do not match."));

        try
        {
            var result = await svc.SignupAsync(req);
            return Ok(ApiResponse<SellerSignupResponse>.Ok(result, "Seller registered. OTPs generated."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Login with email and password.</summary>
    /// <param name="req">Login credentials</param>
    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<SellerAuthResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] SellerLoginRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(ApiResponse<object>.Fail("Email and password are required."));

        var result = await svc.LoginAsync(req);
        if (result is null)
            return Unauthorized(ApiResponse<object>.Fail("Invalid email or password."));

        return Ok(ApiResponse<SellerAuthResponse>.Ok(result, "Login successful."));
    }

    /// <summary>Get current seller profile.</summary>
    [HttpGet("profile")]
    [Authorize(Roles = "Seller")]
    [ProducesResponseType(typeof(ApiResponse<SellerProfileDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProfile()
    {
        var sellerId = GetSellerId();
        var profile = await svc.GetProfileAsync(sellerId);
        if (profile is null)
            return NotFound(ApiResponse<object>.Fail("Seller not found."));

        return Ok(ApiResponse<SellerProfileDto>.Ok(profile));
    }

    /// <summary>Update seller profile information.</summary>
    /// <param name="req">Profile fields to update</param>
    [HttpPut("profile")]
    [Authorize(Roles = "Seller")]
    [ProducesResponseType(typeof(ApiResponse<SellerProfileDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateSellerProfileRequest req)
    {
        var sellerId = GetSellerId();
        var profile = await svc.UpdateProfileAsync(sellerId, req);
        if (profile is null)
            return NotFound(ApiResponse<object>.Fail("Seller not found."));

        return Ok(ApiResponse<SellerProfileDto>.Ok(profile, "Profile updated successfully."));
    }

    /// <summary>Complete seller onboarding.</summary>
    /// <param name="req">Onboarding details: categories, store info, pickup address</param>
    [HttpPost("onboarding")]
    [Authorize(Roles = "Seller")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CompleteOnboarding([FromBody] SellerOnboardingRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.OwnerFullName))
            return BadRequest(ApiResponse<object>.Fail("Owner full name is required."));
        if (string.IsNullOrWhiteSpace(req.DisplayName))
            return BadRequest(ApiResponse<object>.Fail("Display name is required."));
        if (string.IsNullOrWhiteSpace(req.StoreDescription))
            return BadRequest(ApiResponse<object>.Fail("Store description is required."));
        if (string.IsNullOrWhiteSpace(req.PickupAddressLine1))
            return BadRequest(ApiResponse<object>.Fail("Pickup address is required."));
        if (string.IsNullOrWhiteSpace(req.PickupCity))
            return BadRequest(ApiResponse<object>.Fail("Pickup city is required."));
        if (string.IsNullOrWhiteSpace(req.PickupState))
            return BadRequest(ApiResponse<object>.Fail("Pickup state is required."));
        if (string.IsNullOrWhiteSpace(req.PickupPincode))
            return BadRequest(ApiResponse<object>.Fail("Pickup pincode is required."));

        var sellerId = GetSellerId();
        var success = await svc.CompleteOnboardingAsync(sellerId, req);

        if (!success)
            return BadRequest(ApiResponse<object>.Fail("Failed to complete onboarding."));

        return Ok(ApiResponse<object>.Ok(success, "Onboarding completed successfully."));
    }

    private int GetSellerId() =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}

