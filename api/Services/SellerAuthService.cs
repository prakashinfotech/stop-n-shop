using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface ISellerAuthService
{
    Task<SellerSignupResponse> SignupAsync(SellerSignupRequest req);
    Task<SellerAuthResponse?> LoginAsync(SellerLoginRequest req);
    Task<bool> CompleteOnboardingAsync(int sellerId, SellerOnboardingRequest req);
    Task<SellerProfileDto?> GetProfileAsync(int sellerId);
    Task<SellerProfileDto?> UpdateProfileAsync(int sellerId, UpdateSellerProfileRequest req);
    // Phase 3
    Task<bool> RegisterAsync(int userId, SellerRegisterRequest req);
    Task<SellerProfileDto?> GetProfileByUserIdAsync(int userId);
    Task<bool> UpdateBankProfileAsync(int sellerId, UpdateSellerBankRequest req, int updatedBy);
}

public class SellerAuthService(ISellerRepository repo, IConfiguration config) : ISellerAuthService
{
    public async Task<SellerSignupResponse> SignupAsync(SellerSignupRequest req)
    {
        if (req.Password != req.ConfirmPassword)
            throw new InvalidOperationException("Passwords do not match.");

        req.Email = req.Email.Trim();
        var hash = HashPassword(req.Password);

        // Generate OTPs for phone and email verification
        var phoneOtp = GenerateOtp();
        var emailOtp = GenerateOtp();

        var (sellerId, errorCode) = await repo.SignupAsync(req, hash, phoneOtp, emailOtp);

        if (errorCode == "EMAIL_EXISTS")
            throw new InvalidOperationException("An account with this email already exists.");

        var profile = await repo.GetProfileAsync(sellerId);
        var jwt = IssueJwt(sellerId, profile!.Email, profile.BusinessName ?? "Seller");
        return new SellerSignupResponse
        {
            Token = jwt.Token,
            ExpiresAt = jwt.ExpiresAt,
            Seller = profile,
            PhoneOtp = phoneOtp,  // Return OTPs for initial testing phase
            EmailOtp = emailOtp
        };
    }

    public async Task<SellerAuthResponse?> LoginAsync(SellerLoginRequest req)
    {
        req.Email = req.Email.Trim();
        var seller = await repo.GetLoginByEmailAsync(req.Email);
        if (seller is null || string.IsNullOrEmpty(seller.PasswordHash)) return null;
        if (!VerifyPassword(req.Password, seller.PasswordHash)) return null;

        var jwt = IssueJwt(seller.Id, seller.Email, seller.BusinessName ?? seller.DisplayName ?? "Seller");
        seller.PasswordHash = null;
        return new SellerAuthResponse { Token = jwt.Token, ExpiresAt = jwt.ExpiresAt, Seller = seller };
    }

    public Task<bool> CompleteOnboardingAsync(int sellerId, SellerOnboardingRequest req) =>
        repo.CompleteOnboardingAsync(sellerId, req);

    public Task<SellerProfileDto?> GetProfileAsync(int sellerId) =>
        repo.GetProfileAsync(sellerId);

    public Task<SellerProfileDto?> UpdateProfileAsync(int sellerId, UpdateSellerProfileRequest req) =>
        repo.UpdateProfileAsync(sellerId, req);

    private (string Token, DateTime ExpiresAt) IssueJwt(int sellerId, string email, string businessName)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(config["Jwt:SecretKey"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddHours(8);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, sellerId.ToString()),
            new Claim(ClaimTypes.Role, "Seller"),
            new Claim(ClaimTypes.Email, email),
            new Claim("sellerBusiness", businessName),
        };

        var token = new JwtSecurityToken(
            issuer: config["Jwt:Issuer"],
            audience: config["Jwt:Audience"],
            claims: claims,
            expires: expires,
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
        try
        {
            var parts = stored.Split(':', 2);
            if (parts.Length != 2) return false;
            var salt = Convert.FromBase64String(parts[0]);
            var expected = Convert.FromBase64String(parts[1]);
            var actual = Rfc2898DeriveBytes.Pbkdf2(password, salt, 100_000, HashAlgorithmName.SHA256, 32);
            return CryptographicOperations.FixedTimeEquals(expected, actual);
        }
        catch (FormatException)
        {
            return false;
        }
    }

    private static string GenerateOtp()
    {
        var random = new Random();
        return random.Next(100000, 999999).ToString();
    }

    // ── Phase 3 ───────────────────────────────────────────────────────────────

    public Task<bool> RegisterAsync(int userId, SellerRegisterRequest req) =>
        repo.RegisterAsync(userId, req);

    public Task<SellerProfileDto?> GetProfileByUserIdAsync(int userId) =>
        repo.GetProfileByUserIdAsync(userId);

    public Task<bool> UpdateBankProfileAsync(int sellerId, UpdateSellerBankRequest req, int updatedBy) =>
        repo.UpdateBankProfileAsync(sellerId, req, updatedBy);
}
