using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IAuthRepository
{
    Task<int?> GetUserIdByMobileAsync(string mobile);
    Task SaveOtpAsync(int userId, string otp, DateTime expiresAt, int otpType = 2);
    Task<bool> VerifyOtpAsync(int userId, string otp, int otpType = 2);
    Task<UserProfileDto?> GetProfileAsync(int userId);
    Task<UserProfileDto> UpdateProfileAsync(int userId, UpdateProfileRequest req);
    Task<(int UserId, string? ErrorCode)> SignupAsync(SignupRequestDto req, string passwordHash);
    Task<UserLoginDto?> GetLoginByEmailAsync(string email);
    Task<ForgotPasswordResult?> ForgotPasswordAsync(string email);
    Task<bool> ResetPasswordAsync(int userId, string passwordHash);
    Task MarkFirstLoginCompleteAsync(int userId);
}

public class AuthRepository(IConfiguration config) : IAuthRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<int?> GetUserIdByMobileAsync(string mobile)
    {
        using var db = Conn();
        var row = await db.QuerySingleOrDefaultAsync<dynamic>(
            "usp_Auth_User_GetIdByMobile",
            new { Mobile = mobile },
            commandType: System.Data.CommandType.StoredProcedure);
        return row is null ? null : (int?)row.UserId;
    }

    public async Task SaveOtpAsync(int userId, string otp, DateTime expiresAt, int otpType = 2)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Auth_OTP_Send",
            new { UserId = userId, OtpCode = otp, OtpType = otpType, ExpiresAt = expiresAt },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<bool> VerifyOtpAsync(int userId, string otp, int otpType = 2)
    {
        try
        {
            using var db = Conn();
            var result = await db.QuerySingleOrDefaultAsync<int?>(
                "usp_Auth_OTP_Verify",
                new { UserId = userId, OtpCode = otp, OtpType = otpType },
                commandType: System.Data.CommandType.StoredProcedure);
            return result == 1;
        }
        catch (SqlException ex) when (ex.Number is 50005 or 50006 or 50007 or 50008)
        {
            return false;
        }
    }

    public async Task<UserProfileDto?> GetProfileAsync(int userId)
    {
        using var db = Conn();
        var row = await db.QuerySingleOrDefaultAsync<dynamic>(
            "usp_Auth_User_GetProfile",
            new { UserId = userId },
            commandType: System.Data.CommandType.StoredProcedure);
        return row is null ? null : MapProfile(row);
    }

    public async Task<UserProfileDto> UpdateProfileAsync(int userId, UpdateProfileRequest req)
    {
        using var db = Conn();
        var row = await db.QuerySingleAsync<dynamic>(
            "usp_Auth_User_UpdateProfile",
            new { UserId = userId, req.FirstName, req.LastName },
            commandType: System.Data.CommandType.StoredProcedure);
        return MapProfile(row);
    }

    public async Task<(int UserId, string? ErrorCode)> SignupAsync(SignupRequestDto req, string passwordHash)
    {
        using var db = Conn();
        try
        {
            var row = await db.QuerySingleAsync<dynamic>(
                "usp_Auth_User_Register",
                new
                {
                    req.Email,
                    PasswordHash = passwordHash,
                    req.FirstName,
                    req.LastName,
                    req.Mobile
                },
                commandType: System.Data.CommandType.StoredProcedure);
            return ((int)row.UserId, null);
        }
        catch (SqlException ex) when (ex.Number == 50001)
        {
            return (0, "EMAIL_EXISTS");
        }
        catch (SqlException ex) when (ex.Number == 50002)
        {
            return (0, "MOBILE_EXISTS");
        }
    }

    public async Task<UserLoginDto?> GetLoginByEmailAsync(string email)
    {
        using var db = Conn();
        try
        {
            var row = await db.QuerySingleOrDefaultAsync<dynamic>(
                "usp_Auth_User_Login",
                new { Email = email },
                commandType: System.Data.CommandType.StoredProcedure);
            if (row is null) return null;

            return new UserLoginDto
            {
                Id           = (int)row.UserId,
                Email        = row.Email,
                Mobile       = row.Mobile ?? string.Empty,
                FirstName    = row.FirstName ?? string.Empty,
                LastName     = row.LastName ?? string.Empty,
                Role         = row.RoleName ?? "Buyer",
                IsFirstLogin = row.IsFirstLogin is not null ? (bool)row.IsFirstLogin : true,
                PasswordHash = row.PasswordHash ?? string.Empty,
                CreatedAt    = DateTime.UtcNow
            };
        }
        catch (SqlException ex) when (ex.Number == 50003)
        {
            // User not found or inactive
            return null;
        }
        catch (SqlException ex) when (ex.Number == 50004)
        {
            // User is not a customer - they are a seller or other role
            return null;
        }
        catch (SqlException ex)
        {
            // Log the error for debugging
            System.Diagnostics.Debug.WriteLine($"SQL Error in GetLoginByEmailAsync: {ex.Message}");
            return null;
        }
    }

    public async Task<ForgotPasswordResult?> ForgotPasswordAsync(string email)
    {
        using var db = Conn();
        var row = await db.QuerySingleOrDefaultAsync<dynamic>(
            "usp_Auth_User_ForgotPassword",
            new { Email = email },
            commandType: System.Data.CommandType.StoredProcedure);
        if (row is null) return null;
        return new ForgotPasswordResult
        {
            UserId    = (int)row.UserId,
            Email     = row.Email,
            FirstName = row.FirstName
        };
    }

    public async Task<bool> ResetPasswordAsync(int userId, string passwordHash)
    {
        using var db = Conn();
        await db.QuerySingleAsync<dynamic>(
            "usp_Auth_User_ResetPassword",
            new { UserId = userId, NewPasswordHash = passwordHash },
            commandType: System.Data.CommandType.StoredProcedure);
        return true;
    }

    public async Task MarkFirstLoginCompleteAsync(int userId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Auth_MarkFirstLoginComplete",
            new { UserId = userId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static UserProfileDto MapProfile(dynamic row) => new()
    {
        Id        = (int)row.UserId,
        Email     = row.Email,
        Mobile    = row.Mobile ?? string.Empty,
        FirstName = row.FirstName,
        LastName  = row.LastName,
        Role      = row.RoleName ?? "Buyer",
        CreatedAt = row.CreatedAt
    };
}
