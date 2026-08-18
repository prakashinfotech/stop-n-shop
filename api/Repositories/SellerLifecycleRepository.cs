using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

/// <summary>
/// Phase 3 — Seller lifecycle: bank accounts, warehouses, vendor agreements,
/// onboarding stage tracking, settlements, performance scoring.
/// All access via stored procedures; no inline SQL.
/// </summary>
public interface ISellerLifecycleRepository
{
    // Onboarding
    Task<OnboardingStageDto?> AdvanceStageAsync(int sellerId, string stage, int completedBy);

    // Documents
    Task<SellerDocumentDto?> UploadDocumentAsync(int sellerId, byte type, string url, int uploadedBy);
    Task<SellerDocumentDto?> VerifyDocumentAsync(int documentId, int verifiedBy, bool isVerified);

    // Bank accounts
    Task<SellerBankAccountDto?> AddBankAccountAsync(int sellerId, AddSellerBankAccountRequest req, int createdBy);
    Task<IEnumerable<SellerBankAccountDto>> GetBankAccountsAsync(int sellerId);
    Task<bool> SetPrimaryBankAccountAsync(int bankAccountId, int sellerId, int updatedBy);

    // Warehouses
    Task<SellerWarehouseDto?> UpsertWarehouseAsync(int sellerId, UpsertSellerWarehouseRequest req, int updatedBy);
    Task<IEnumerable<SellerWarehouseDto>> GetWarehousesAsync(int sellerId);

    // Vendor agreement
    Task<VendorAgreementDto?> AcceptAgreementAsync(int sellerId, string version, string? ip, string? ua, string? docUrl, int acceptedBy);
    Task<VendorAgreementDto?> GetLatestAgreementAsync(int sellerId);

    // Settlement
    Task<SellerSettlementDto?> CalculateSettlementAsync(int sellerId, DateTime periodStart, DateTime periodEnd, int calculatedBy);
    Task<(IEnumerable<SellerSettlementDto> Items, int TotalCount)> ListSettlementsAsync(int sellerId, int page, int pageSize);
    Task<SellerSettlementDetailDto> GetSettlementAsync(int settlementId, int sellerId);
    Task<IEnumerable<int>> GetSellersWithDueSettlementsAsync(DateTime cutoffDate);

    // Performance score
    Task<SellerPerformanceScoreDto?> RecomputeScoreAsync(int sellerId, DateTime? snapshotDate, int windowDays);
    Task<SellerPerformanceScoreDto?> GetLatestScoreAsync(int sellerId);
    Task<IEnumerable<int>> GetAllActiveSellerIdsAsync();
}

public class SellerLifecycleRepository(IConfiguration config) : ISellerLifecycleRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<OnboardingStageDto?> AdvanceStageAsync(int sellerId, string stage, int completedBy)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<OnboardingStageDto>(
            "usp_Seller_Onboarding_AdvanceStage",
            new { SellerId = sellerId, Stage = stage, CompletedBy = completedBy },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<SellerDocumentDto?> UploadDocumentAsync(int sellerId, byte type, string url, int uploadedBy)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerDocumentDto>(
            "usp_Seller_Document_Upload",
            new { SellerId = sellerId, DocumentType = type, DocumentUrl = url, UploadedBy = uploadedBy },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<SellerDocumentDto?> VerifyDocumentAsync(int documentId, int verifiedBy, bool isVerified)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerDocumentDto>(
            "usp_Seller_Document_Verify",
            new { DocumentId = documentId, VerifiedBy = verifiedBy, IsVerified = isVerified },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<SellerBankAccountDto?> AddBankAccountAsync(int sellerId, AddSellerBankAccountRequest req, int createdBy)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerBankAccountDto>(
            "usp_Seller_BankAccount_Add",
            new
            {
                SellerId = sellerId,
                req.AccountHolderName,
                req.BankName,
                req.AccountNumber,
                req.IfscCode,
                req.BranchName,
                req.IsPrimary,
                CreatedBy = createdBy
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<SellerBankAccountDto>> GetBankAccountsAsync(int sellerId)
    {
        using var db = Conn();
        return await db.QueryAsync<SellerBankAccountDto>(
            "usp_Seller_BankAccount_GetAll",
            new { SellerId = sellerId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<bool> SetPrimaryBankAccountAsync(int bankAccountId, int sellerId, int updatedBy)
    {
        using var db = Conn();
        var result = await db.QuerySingleOrDefaultAsync<dynamic>(
            "usp_Seller_BankAccount_SetPrimary",
            new { BankAccountId = bankAccountId, SellerId = sellerId, UpdatedBy = updatedBy },
            commandType: CommandType.StoredProcedure);
        return result is not null;
    }

    public async Task<SellerWarehouseDto?> UpsertWarehouseAsync(int sellerId, UpsertSellerWarehouseRequest req, int updatedBy)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerWarehouseDto>(
            "usp_Seller_Warehouse_Upsert",
            new
            {
                req.SellerWarehouseId,
                SellerId = sellerId,
                req.Name,
                req.ContactName,
                req.ContactPhone,
                req.AddressLine1,
                req.AddressLine2,
                req.City,
                req.State,
                req.Pincode,
                req.IsPrimary,
                UpdatedBy = updatedBy
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<SellerWarehouseDto>> GetWarehousesAsync(int sellerId)
    {
        using var db = Conn();
        return await db.QueryAsync<SellerWarehouseDto>(
            "usp_Seller_Warehouse_GetAll",
            new { SellerId = sellerId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<VendorAgreementDto?> AcceptAgreementAsync(int sellerId, string version, string? ip, string? ua, string? docUrl, int acceptedBy)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<VendorAgreementDto>(
            "usp_Seller_VendorAgreement_Accept",
            new
            {
                SellerId = sellerId,
                Version = version,
                AcceptedIp = ip,
                AcceptedUserAgent = ua,
                DocumentUrl = docUrl,
                AcceptedBy = acceptedBy
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<VendorAgreementDto?> GetLatestAgreementAsync(int sellerId)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<VendorAgreementDto>(
            "usp_Seller_VendorAgreement_GetLatest",
            new { SellerId = sellerId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<SellerSettlementDto?> CalculateSettlementAsync(int sellerId, DateTime periodStart, DateTime periodEnd, int calculatedBy)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerSettlementDto>(
            "usp_Seller_Settlement_Calculate",
            new
            {
                SellerId = sellerId,
                PeriodStart = periodStart,
                PeriodEnd = periodEnd,
                CalculatedBy = calculatedBy
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<(IEnumerable<SellerSettlementDto> Items, int TotalCount)> ListSettlementsAsync(int sellerId, int page, int pageSize)
    {
        using var db = Conn();
        using var grid = await db.QueryMultipleAsync(
            "usp_Seller_Settlement_List",
            new { SellerId = sellerId, Page = page, PageSize = pageSize },
            commandType: CommandType.StoredProcedure);

        var totalCount = await grid.ReadFirstAsync<int>();
        var items     = await grid.ReadAsync<SellerSettlementDto>();
        return (items, totalCount);
    }

    public async Task<SellerSettlementDetailDto> GetSettlementAsync(int settlementId, int sellerId)
    {
        using var db = Conn();
        using var grid = await db.QueryMultipleAsync(
            "usp_Seller_Settlement_GetById",
            new { SettlementId = settlementId, SellerId = sellerId },
            commandType: CommandType.StoredProcedure);

        var header = await grid.ReadFirstOrDefaultAsync<SellerSettlementDto>();
        var lines  = await grid.ReadAsync<SellerSettlementLineDto>();
        return new SellerSettlementDetailDto { Settlement = header, Lines = lines.ToList() };
    }

    public async Task<IEnumerable<int>> GetSellersWithDueSettlementsAsync(DateTime cutoffDate)
    {
        using var db = Conn();
        return await db.QueryAsync<int>(
            "usp_Seller_Settlement_DueSellers",
            new { CutoffDate = cutoffDate },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<SellerPerformanceScoreDto?> RecomputeScoreAsync(int sellerId, DateTime? snapshotDate, int windowDays)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerPerformanceScoreDto>(
            "usp_Seller_PerformanceScore_Recompute",
            new { SellerId = sellerId, SnapshotDate = snapshotDate, WindowDays = windowDays },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<SellerPerformanceScoreDto?> GetLatestScoreAsync(int sellerId)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<SellerPerformanceScoreDto>(
            "usp_Seller_PerformanceScore_GetLatest",
            new { SellerId = sellerId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<IEnumerable<int>> GetAllActiveSellerIdsAsync()
    {
        using var db = Conn();
        return await db.QueryAsync<int>(
            "usp_Seller_PerformanceScore_AllSellers",
            commandType: CommandType.StoredProcedure);
    }
}
