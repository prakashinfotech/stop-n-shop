using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using Twilio;
using Twilio.Rest.Api.V2010.Account;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IAuthService
{
    Task<(bool Found, string? OtpCode)> SendOtpAsync(string mobile);
    Task<AuthTokenResponse?> VerifyOtpAsync(string mobile, string otp);
    Task<AuthTokenResponse> SignupAsync(SignupRequestDto req);
    Task<AuthTokenResponse?> LoginAsync(LoginRequestDto req);
    Task<UserProfileDto?> GetProfileAsync(int userId);
    Task<UserProfileDto> UpdateProfileAsync(int userId, UpdateProfileRequest req);
    Task<bool> ForgotPasswordAsync(string email);
    Task<ForgotPasswordResult?> ForgotPasswordLookupAsync(string email);
    Task<bool> VerifyForgotPasswordOtpAsync(int userId, string otp);
    Task<bool> ResetPasswordAsync(int userId, string newPassword);
    Task MarkFirstLoginCompleteAsync(int userId);
}

public class AuthService(IAuthRepository repo, IConfiguration config, IEmailService emailSvc, ILogger<AuthService> logger) : IAuthService
{
    public async Task<(bool Found, string? OtpCode)> SendOtpAsync(string mobile)
    {
        var userId = await repo.GetUserIdByMobileAsync(mobile);
        if (userId is null) return (false, null);

        var otp       = new Random().Next(100000, 999999).ToString();
        var expiresAt = DateTime.UtcNow.AddMinutes(5);

        await repo.SaveOtpAsync(userId.Value, otp, expiresAt);

        // Twilio SMS sending disabled for now — just return the OTP for screen display
        // TODO: Reconfigure Twilio credentials in appsettings if SMS delivery needed

        return (true, otp);
    }

    public async Task<AuthTokenResponse?> VerifyOtpAsync(string mobile, string otp)
    {
        var userId = await repo.GetUserIdByMobileAsync(mobile);
        if (userId is null) return null;

        var verified = await repo.VerifyOtpAsync(userId.Value, otp);
        if (!verified) return null;

        var profile = await repo.GetProfileAsync(userId.Value);
        if (profile is null) return null;

        var jwt = IssueJwt(userId.Value, mobile, profile.Email, profile.Role);
        return new AuthTokenResponse { Token = jwt.Token, ExpiresAt = jwt.ExpiresAt, User = profile };
    }

    public async Task<AuthTokenResponse> SignupAsync(SignupRequestDto req)
    {
        var hash = HashPassword(req.Password);
        var (userId, errorCode) = await repo.SignupAsync(req, hash);

        if (errorCode == "EMAIL_EXISTS")
            throw new InvalidOperationException("An account with this email already exists.");
        if (errorCode == "MOBILE_EXISTS")
            throw new InvalidOperationException("An account with this mobile number already exists.");

        var profile = await repo.GetProfileAsync(userId);
        var jwt     = IssueJwt(userId, req.Mobile, req.Email, "Buyer");
        return new AuthTokenResponse { Token = jwt.Token, ExpiresAt = jwt.ExpiresAt, User = profile! };
    }

    public async Task<AuthTokenResponse?> LoginAsync(LoginRequestDto req)
    {
        var user = await repo.GetLoginByEmailAsync(req.Email);
        if (user is null || string.IsNullOrEmpty(user.PasswordHash)) return null;
        if (!VerifyPassword(req.Password, user.PasswordHash)) return null;

        var jwt = IssueJwt(user.Id, user.Mobile, user.Email, user.Role);
        return new AuthTokenResponse { Token = jwt.Token, ExpiresAt = jwt.ExpiresAt, User = user };
    }

    public Task<UserProfileDto?> GetProfileAsync(int userId) => repo.GetProfileAsync(userId);

    public Task<UserProfileDto> UpdateProfileAsync(int userId, UpdateProfileRequest req) =>
        repo.UpdateProfileAsync(userId, req);

    public async Task<bool> ForgotPasswordAsync(string email)
    {
        // Always returns true to prevent user enumeration
        await repo.ForgotPasswordAsync(email);
        return true;
    }

    public async Task<ForgotPasswordResult?> ForgotPasswordLookupAsync(string email)
    {
        var result = await repo.ForgotPasswordAsync(email);
        if (result is null) return null;

        var otp       = new Random().Next(100000, 999999).ToString();
        var expiresAt = DateTime.UtcNow.AddMinutes(10);
        await repo.SaveOtpAsync(result.UserId, otp, expiresAt, otpType: 1);
        logger.LogWarning("DEV — Forgot-password OTP for {Email}: {Otp}", result.Email, otp);
        await emailSvc.SendForgotPasswordOtpAsync(result.Email, result.FirstName ?? string.Empty, otp);

        return result;
    }

    public async Task<bool> VerifyForgotPasswordOtpAsync(int userId, string otp)
    {
        return await repo.VerifyOtpAsync(userId, otp, otpType: 1);
    }

    public async Task<bool> ResetPasswordAsync(int userId, string newPassword)
    {
        var hash = HashPassword(newPassword);
        return await repo.ResetPasswordAsync(userId, hash);
    }

    public Task MarkFirstLoginCompleteAsync(int userId) => repo.MarkFirstLoginCompleteAsync(userId);

    // ── JWT ────────────────────────────────────────────────────────────────────

    private (string Token, DateTime ExpiresAt) IssueJwt(int userId, string mobile, string? email, string role)
    {
        var key     = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:SecretKey"]!));
        var creds   = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddHours(8);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ClaimTypes.Role, role),
            new("mobile", mobile),
        };
        if (!string.IsNullOrEmpty(email))
            claims.Add(new(ClaimTypes.Email, email));

        var token = new JwtSecurityToken(
            issuer:             config["Jwt:Issuer"],
            audience:           config["Jwt:Audience"],
            claims:             claims,
            expires:            expires,
            signingCredentials: creds);

        return (new JwtSecurityTokenHandler().WriteToken(token), expires);
    }

    private static string HashPassword(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(16);
        var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, 100_000, HashAlgorithmName.SHA256, 32);
        return $"{Convert.ToBase64String(salt)}:{Convert.ToBase64String(hash)}";
    }

    private static bool VerifyPassword(string password, string stored)
    {
        var parts = stored.Split(':', 2);
        if (parts.Length != 2) return false;
        var salt     = Convert.FromBase64String(parts[0]);
        var expected = Convert.FromBase64String(parts[1]);
        var actual   = Rfc2898DeriveBytes.Pbkdf2(password, salt, 100_000, HashAlgorithmName.SHA256, 32);
        return CryptographicOperations.FixedTimeEquals(expected, actual);
    }
}
