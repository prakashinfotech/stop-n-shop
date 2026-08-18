using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

[ApiController]
[Route("api/auth")]
[Produces("application/json")]
public class AuthController(IAuthService authService) : ControllerBase
{
    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // ── Buyer Register ────────────────────────────────────────────────────────

    /// <summary>Register a new buyer account. Auto-logs in on success.</summary>
    [HttpPost("buyer/register")]
    [HttpPost("signup")]                          // legacy alias
    [ProducesResponseType(typeof(ApiResponse<AuthTokenResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Register([FromBody] SignupRequestDto req)
    {
        if (string.IsNullOrWhiteSpace(req.FirstName) || string.IsNullOrWhiteSpace(req.LastName)
            || string.IsNullOrWhiteSpace(req.Email)  || string.IsNullOrWhiteSpace(req.Mobile)
            || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(ApiResponse<object>.Fail("All required fields must be provided."));

        if (req.Password.Length < 8)
            return BadRequest(ApiResponse<object>.Fail("Password must be at least 8 characters."));

        try
        {
            var result = await authService.SignupAsync(req);
            return Ok(ApiResponse<AuthTokenResponse>.Ok(result, "Account created successfully."));
        }
        catch (InvalidOperationException ex)
        {
            return Conflict(ApiResponse<object>.Fail(ex.Message));
        }
    }

    // ── Buyer Login ───────────────────────────────────────────────────────────

    /// <summary>Login with email and password.</summary>
    [HttpPost("buyer/login")]
    [HttpPost("login")]                           // legacy alias
    [ProducesResponseType(typeof(ApiResponse<AuthTokenResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto req)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(ApiResponse<object>.Fail("Email and password are required."));

        var result = await authService.LoginAsync(req);
        if (result is null)
            return Unauthorized(ApiResponse<object>.Fail("Invalid email or password."));

        return Ok(ApiResponse<AuthTokenResponse>.Ok(result, "Login successful."));
    }

    // ── Seller Login ───────────────────────────────────────────────────────────

    /// <summary>Seller login with email and password.</summary>
    [HttpPost("seller/login")]
    [ProducesResponseType(typeof(ApiResponse<AuthTokenResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SellerLogin([FromBody] LoginRequestDto req)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(ApiResponse<object>.Fail("Email and password are required."));

        var result = await authService.LoginAsync(req);
        if (result is null)
            return Unauthorized(ApiResponse<object>.Fail("Invalid email or password."));

        if (result.User.Role != "Seller")
            return Unauthorized(ApiResponse<object>.Fail("This account is not registered as a seller."));

        return Ok(ApiResponse<AuthTokenResponse>.Ok(result, "Seller login successful."));
    }

    // ── Dispatcher Login ───────────────────────────────────────────────────────

    /// <summary>Dispatcher (delivery agent) login with email and password.</summary>
    [HttpPost("dispatcher/login")]
    [ProducesResponseType(typeof(ApiResponse<AuthTokenResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> DispatcherLogin([FromBody] LoginRequestDto req)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(ApiResponse<object>.Fail("Email and password are required."));

        var result = await authService.LoginAsync(req);
        if (result is null)
            return Unauthorized(ApiResponse<object>.Fail("Invalid email or password."));

        if (result.User.Role != "Dispatcher")
            return Unauthorized(ApiResponse<object>.Fail("This account is not registered as a dispatcher."));

        return Ok(ApiResponse<AuthTokenResponse>.Ok(result, "Dispatcher login successful."));
    }

    // ── Admin Login ────────────────────────────────────────────────────────────

    /// <summary>Admin login with email and password.</summary>
    [HttpPost("admin/login")]
    [ProducesResponseType(typeof(ApiResponse<AuthTokenResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> AdminLogin([FromBody] LoginRequestDto req)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(ApiResponse<object>.Fail("Email and password are required."));

        var result = await authService.LoginAsync(req);
        if (result is null)
            return Unauthorized(ApiResponse<object>.Fail("Invalid email or password."));

        if (result.User.Role != "Admin")
            return Unauthorized(ApiResponse<object>.Fail("This account is not registered as an admin."));

        return Ok(ApiResponse<AuthTokenResponse>.Ok(result, "Admin login successful."));
    }

    // ── OTP ───────────────────────────────────────────────────────────────────

    /// <summary>Send a 6-digit OTP to the registered mobile number.</summary>
    [HttpPost("otp/send")]
    [HttpPost("send-otp")]                        // legacy alias
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> SendOtp([FromBody] SendOtpRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Mobile) || req.Mobile.Length != 10)
            return BadRequest(ApiResponse<object>.Fail("Enter a valid 10-digit mobile number."));

        var (found, otpCode) = await authService.SendOtpAsync(req.Mobile);
        if (!found)
            return NotFound(ApiResponse<object>.Fail("No account found with this mobile number."));

        return Ok(ApiResponse<object>.Ok(new { otpCode }, "OTP sent successfully."));
    }

    /// <summary>Verify OTP and return a JWT token on success.</summary>
    [HttpPost("otp/verify")]
    [HttpPost("verify-otp")]                      // legacy alias
    [ProducesResponseType(typeof(ApiResponse<AuthTokenResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest req)
    {
        var result = await authService.VerifyOtpAsync(req.Mobile, req.Otp);
        if (result is null)
            return Unauthorized(ApiResponse<object>.Fail("Invalid or expired OTP."));

        return Ok(ApiResponse<AuthTokenResponse>.Ok(result, "Login successful."));
    }

    // ── Password Reset ────────────────────────────────────────────────────────

    /// <summary>Initiate password reset — returns userId if account exists, null otherwise (anti-enumeration via consistent message).</summary>
    [HttpPost("forgot-password")]
    [ProducesResponseType(typeof(ApiResponse<ForgotPasswordResult>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email))
            return BadRequest(ApiResponse<object>.Fail("Email is required."));

        var result = await authService.ForgotPasswordLookupAsync(req.Email);
        // Always return 200 with a consistent message to prevent user enumeration.
        // The userId is included only when the account exists; the client must handle null gracefully.
        return Ok(ApiResponse<ForgotPasswordResult?>.Ok(result, "If an account exists, you can now reset your password."));
    }

    /// <summary>Verify the email OTP issued during forgot-password flow.</summary>
    [HttpPost("forgot-password/verify-otp")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> VerifyForgotPasswordOtp([FromBody] VerifyForgotPasswordOtpRequest req)
    {
        var verified = await authService.VerifyForgotPasswordOtpAsync(req.UserId, req.Otp);
        if (!verified)
            return Unauthorized(ApiResponse<object>.Fail("Invalid or expired OTP."));

        return Ok(ApiResponse<object>.Ok(null!, "OTP verified."));
    }

    /// <summary>Reset password using userId and a new password.</summary>
    [HttpPost("reset-password")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest req)
    {
        if (req.UserId <= 0 || string.IsNullOrWhiteSpace(req.NewPassword))
            return BadRequest(ApiResponse<object>.Fail("UserId and new password are required."));

        if (req.NewPassword.Length < 8)
            return BadRequest(ApiResponse<object>.Fail("Password must be at least 8 characters."));

        var success = await authService.ResetPasswordAsync(req.UserId, req.NewPassword);
        if (!success)
            return BadRequest(ApiResponse<object>.Fail("Password reset failed."));

        return Ok(ApiResponse<object>.Ok(null!, "Password reset successfully."));
    }

    // ── Profile ───────────────────────────────────────────────────────────────

    /// <summary>Get authenticated user's profile.</summary>
    [Authorize]
    [HttpGet("profile")]
    [HttpGet("me")]
    [ProducesResponseType(typeof(ApiResponse<UserProfileDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetProfile()
    {
        var profile = await authService.GetProfileAsync(CurrentUserId);
        if (profile is null) return NotFound(ApiResponse<object>.Fail("User not found."));
        return Ok(ApiResponse<UserProfileDto>.Ok(profile));
    }

    /// <summary>Update authenticated user's profile.</summary>
    [Authorize]
    [HttpPut("profile")]
    [ProducesResponseType(typeof(ApiResponse<UserProfileDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest req)
    {
        var profile = await authService.UpdateProfileAsync(CurrentUserId, req);
        return Ok(ApiResponse<UserProfileDto>.Ok(profile, "Profile updated."));
    }

    /// <summary>Mark the first login as complete. Called after first-time user greeting modal is acknowledged.</summary>
    [Authorize]
    [HttpPost("mark-first-login-complete")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> MarkFirstLoginComplete()
    {
        await authService.MarkFirstLoginCompleteAsync(CurrentUserId);
        return Ok(ApiResponse<object>.Ok(null!, "First login marked as complete."));
    }
}
