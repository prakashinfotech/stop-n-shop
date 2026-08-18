using System.Text.Json.Serialization;

namespace ShopNShop.Api.DTOs;

public record SendOtpRequest(string Mobile);
public record VerifyOtpRequest(string Mobile, string Otp);
public record SendOtpResponse(string OtpCode);

public class LoginRequestDto
{
    public string Email      { get; set; } = string.Empty;
    public string Password   { get; set; } = string.Empty;
    public bool   RememberMe { get; set; }
}

public class SignupRequestDto
{
    public string  FirstName   { get; set; } = string.Empty;
    public string  LastName    { get; set; } = string.Empty;
    public string  Email       { get; set; } = string.Empty;
    public string  Mobile      { get; set; } = string.Empty;
    public string  CountryCode { get; set; } = "+91";
    public string  Password    { get; set; } = string.Empty;
}

public class ForgotPasswordRequest
{
    public string Email { get; set; } = string.Empty;
}

public class ResetPasswordRequest
{
    public int    UserId      { get; set; }
    public string NewPassword { get; set; } = string.Empty;
}

public class ForgotPasswordResult
{
    public int     UserId    { get; set; }
    public string  Email     { get; set; } = string.Empty;
    public string? FirstName { get; set; }
}

public class VerifyForgotPasswordOtpRequest
{
    public int    UserId { get; set; }
    public string Otp    { get; set; } = string.Empty;
}

public class AuthTokenResponse
{
    public string      Token     { get; set; } = string.Empty;
    public DateTime    ExpiresAt { get; set; }
    public UserProfileDto User   { get; set; } = null!;
}

public class UserProfileDto
{
    public int       Id           { get; set; }
    public string    Mobile       { get; set; } = string.Empty;
    public string?   FirstName    { get; set; }
    public string?   LastName     { get; set; }
    public string?   Email        { get; set; }
    public string    Role         { get; set; } = "Buyer";
    public bool      IsFirstLogin { get; set; }
    public DateTime  CreatedAt    { get; set; }
}

public class UserLoginDto : UserProfileDto
{
    [JsonIgnore]
    public string? PasswordHash { get; set; }
}

public class UpdateProfileRequest
{
    public string? FirstName { get; set; }
    public string? LastName  { get; set; }
}
