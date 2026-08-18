using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface ISellerRepository
{
    Task<(int SellerId, string? ErrorCode)> SignupAsync(SellerSignupRequest req, string passwordHash, string phoneOtp, string emailOtp);
    Task<SellerProfileDto?> GetLoginByEmailAsync(string email);
    Task<SellerProfileDto?> GetProfileAsync(int sellerId);
    Task<SellerProfileDto?> UpdateProfileAsync(int sellerId, UpdateSellerProfileRequest req);
    Task<bool> CompleteOnboardingAsync(int sellerId, SellerOnboardingRequest req);
    // Phase 3
    Task<bool> RegisterAsync(int userId, SellerRegisterRequest req);
    Task<SellerProfileDto?> GetProfileByUserIdAsync(int userId);
    Task<bool> UpdateBankProfileAsync(int sellerId, UpdateSellerBankRequest req, int updatedBy);
}

public class SellerRepository(IConfiguration config) : ISellerRepository
{
    private SqlConnection Conn() =>
        new(config.GetConnectionString("ShopNShop"));

    public async Task<(int SellerId, string? ErrorCode)> SignupAsync(SellerSignupRequest req, string passwordHash, string phoneOtp, string emailOtp)
    {
        using var db = Conn();

        var param = new DynamicParameters();
        param.Add("@Email", req.Email);
        param.Add("@PhoneNumber", req.PhoneNumber);
        param.Add("@PasswordHash", passwordHash);
        param.Add("@SellerId", dbType: System.Data.DbType.Int32, direction: System.Data.ParameterDirection.Output);
        param.Add("@ErrorCode", dbType: System.Data.DbType.String, direction: System.Data.ParameterDirection.Output, size: 50);

        await db.ExecuteAsync("sp_SellerSignup", param, commandType: System.Data.CommandType.StoredProcedure);

        var sellerId = param.Get<int?>("@SellerId") ?? 0;
        var errorCode = param.Get<string?>("@ErrorCode");

        return (sellerId, errorCode);
    }

    public async Task<SellerProfileDto?> GetLoginByEmailAsync(string email)
    {
        using var db = Conn();
        try
        {
            return await db.QuerySingleOrDefaultAsync<SellerProfileDto>(
                "sp_SellerLogin",
                new { Email = email },
                commandType: System.Data.CommandType.StoredProcedure);
        }
        catch (SqlException ex) when (ex.Number == 50003)
        {
            // User not found or inactive
            return null;
        }
        catch (SqlException ex) when (ex.Number == 50005)
        {
            // User is not a seller - they are a customer or other role
            return null;
        }
        catch (SqlException ex) when (ex.Number == 50006)
        {
            // Seller profile not found - user has seller role but no seller record
            return null;
        }
        catch (SqlException ex)
        {
            // Log the error for debugging
            System.Diagnostics.Debug.WriteLine($"SQL Error in SellerRepository.GetLoginByEmailAsync: {ex.Message}");
            return null;
        }
    }

    public async Task<SellerProfileDto?> GetProfileAsync(int sellerId)
    {
        using var db = Conn();

        return await db.QuerySingleOrDefaultAsync<SellerProfileDto>(
            "sp_SellerGetProfile",
            new { SellerId = sellerId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<SellerProfileDto?> UpdateProfileAsync(int sellerId, UpdateSellerProfileRequest req)
    {
        using var db = Conn();

        return await db.QuerySingleOrDefaultAsync<SellerProfileDto>(
            "sp_SellerUpdateProfile",
            new
            {
                SellerId = sellerId,
                BusinessName = req.BusinessName,
                OwnerName = req.OwnerName,
                PhoneNumber = req.PhoneNumber,
                GSTNumber = req.GSTNumber,
                Address = req.Address,
                City = req.City,
                State = req.State,
                Pincode = req.Pincode,
                BannerUrl = req.BannerUrl,
                LogoUrl = req.LogoUrl,
                SupportEmail = req.SupportEmail,
                SupportPhone = req.SupportPhone,
                Description = req.Description
            },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<bool> CompleteOnboardingAsync(int sellerId, SellerOnboardingRequest req)
    {
        using var db = Conn();

        var selectedCategories = req.AllCategories ? null : System.Text.Json.JsonSerializer.Serialize(req.SelectedCategoryIds);

        await db.ExecuteAsync(
            "sp_SellerCompleteOnboarding",
            new
            {
                SellerId = sellerId,
                OwnerFullName = req.OwnerFullName,
                DisplayName = req.DisplayName,
                StoreDescription = req.StoreDescription,
                IsPhoneVerified = req.IsPhoneVerified,
                IsEmailVerified = req.IsEmailVerified,
                IsIdVerified = req.IsIdVerified,
                SelectedCategories = selectedCategories,
                PickupAddressLine1 = req.PickupAddressLine1,
                PickupAddressLine2 = req.PickupAddressLine2,
                PickupCity = req.PickupCity,
                PickupState = req.PickupState,
                PickupPincode = req.PickupPincode,
                PickupLandmark = req.PickupLandmark
            },
            commandType: System.Data.CommandType.StoredProcedure);

        return true;
    }

    // ── Phase 3 ───────────────────────────────────────────────────────────────

    public async Task<bool> RegisterAsync(int userId, SellerRegisterRequest req)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Seller_Register",
            new
            {
                UserId             = userId,
                req.BusinessName,
                req.GstNumber,
                req.PanNumber,
                req.BusinessAddressId,
                req.BankAccountNumber,
                req.BankIfscCode,
                req.BankName
            },
            commandType: System.Data.CommandType.StoredProcedure);
        return true;
    }

    public async Task<SellerProfileDto?> GetProfileByUserIdAsync(int userId)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerProfileDto>(
            "usp_Seller_GetProfile",
            new { UserId = userId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<bool> UpdateBankProfileAsync(int sellerId, UpdateSellerBankRequest req, int updatedBy)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Seller_UpdateProfile",
            new
            {
                SellerId           = sellerId,
                req.BusinessName,
                req.BankAccountNumber,
                req.BankIfscCode,
                req.BankName,
                UpdatedBy          = updatedBy
            },
            commandType: System.Data.CommandType.StoredProcedure);
        return true;
    }
}
