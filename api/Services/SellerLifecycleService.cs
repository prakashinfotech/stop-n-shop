using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface ISellerLifecycleService
{
    Task<OnboardingStageDto?> AdvanceStageAsync(int sellerId, string stage, int actorUserId);
    Task<SellerDocumentDto?> UploadDocumentAsync(int sellerId, UploadSellerDocumentRequest req, int actorUserId);
    Task<SellerDocumentDto?> VerifyDocumentAsync(int documentId, int verifiedBy, bool isVerified);

    Task<SellerBankAccountDto?> AddBankAccountAsync(int sellerId, AddSellerBankAccountRequest req, int actorUserId);
    Task<IEnumerable<SellerBankAccountDto>> GetBankAccountsAsync(int sellerId);
    Task<bool> SetPrimaryBankAccountAsync(int bankAccountId, int sellerId, int actorUserId);

    Task<SellerWarehouseDto?> UpsertWarehouseAsync(int sellerId, UpsertSellerWarehouseRequest req, int actorUserId);
    Task<IEnumerable<SellerWarehouseDto>> GetWarehousesAsync(int sellerId);

    Task<VendorAgreementDto?> AcceptAgreementAsync(int sellerId, AcceptVendorAgreementRequest req, string? ip, string? ua, int actorUserId);
    Task<VendorAgreementDto?> GetLatestAgreementAsync(int sellerId);

    Task<SellerSettlementDto?> CalculateSettlementAsync(int sellerId, DateTime periodStart, DateTime periodEnd, int actorUserId);
    Task<(IEnumerable<SellerSettlementDto> Items, int TotalCount)> ListSettlementsAsync(int sellerId, int page, int pageSize);
    Task<SellerSettlementDetailDto> GetSettlementAsync(int settlementId, int sellerId);

    Task<SellerPerformanceScoreDto?> RecomputeScoreAsync(int sellerId, int windowDays = 30);
    Task<SellerPerformanceScoreDto?> GetLatestScoreAsync(int sellerId);

    /// <summary>Settlement formula helper — kept pure for unit testing.</summary>
    SettlementMath ComputeLineMath(decimal gross, decimal? sellerCommission, decimal defaultRate, decimal tdsRate, decimal penalty = 0);
}

/// <summary>Pure value-type result of the per-line settlement formula.</summary>
public readonly record struct SettlementMath(
    decimal Gross,
    decimal Commission,
    decimal Tds,
    decimal Penalty,
    decimal Net);

public class SellerLifecycleService(
    ISellerLifecycleRepository repo,
    ILogger<SellerLifecycleService> log) : ISellerLifecycleService
{
    public async Task<OnboardingStageDto?> AdvanceStageAsync(int sellerId, string stage, int actorUserId)
    {
        var allowed = new[] { "business", "bank", "pickup", "documents", "agreement", "complete" };
        if (!allowed.Contains(stage))
            throw new ArgumentException($"Unknown onboarding stage '{stage}'.");

        var result = await repo.AdvanceStageAsync(sellerId, stage, actorUserId);
        Audit(actorUserId, "seller.onboarding.advance", new { sellerId, stage });
        return result;
    }

    public async Task<SellerDocumentDto?> UploadDocumentAsync(int sellerId, UploadSellerDocumentRequest req, int actorUserId)
    {
        if (req.DocumentType is < 1 or > 4)
            throw new ArgumentException("DocumentType must be 1..4.");
        if (string.IsNullOrWhiteSpace(req.DocumentUrl))
            throw new ArgumentException("DocumentUrl is required.");

        var result = await repo.UploadDocumentAsync(sellerId, req.DocumentType, req.DocumentUrl, actorUserId);
        Audit(actorUserId, "seller.document.upload", new { sellerId, type = req.DocumentType });
        return result;
    }

    public async Task<SellerDocumentDto?> VerifyDocumentAsync(int documentId, int verifiedBy, bool isVerified)
    {
        var result = await repo.VerifyDocumentAsync(documentId, verifiedBy, isVerified);
        Audit(verifiedBy, "seller.document.verify", new { documentId, isVerified });
        return result;
    }

    public async Task<SellerBankAccountDto?> AddBankAccountAsync(int sellerId, AddSellerBankAccountRequest req, int actorUserId)
    {
        if (string.IsNullOrWhiteSpace(req.AccountNumber)) throw new ArgumentException("Account number is required.");
        if (string.IsNullOrWhiteSpace(req.IfscCode))      throw new ArgumentException("IFSC code is required.");
        if (string.IsNullOrWhiteSpace(req.BankName))      throw new ArgumentException("Bank name is required.");

        var result = await repo.AddBankAccountAsync(sellerId, req, actorUserId);
        Audit(actorUserId, "seller.bank.add", new { sellerId, bankAccountId = result?.BankAccountId, primary = req.IsPrimary });
        return result;
    }

    public Task<IEnumerable<SellerBankAccountDto>> GetBankAccountsAsync(int sellerId) =>
        repo.GetBankAccountsAsync(sellerId);

    public async Task<bool> SetPrimaryBankAccountAsync(int bankAccountId, int sellerId, int actorUserId)
    {
        var ok = await repo.SetPrimaryBankAccountAsync(bankAccountId, sellerId, actorUserId);
        if (ok) Audit(actorUserId, "seller.bank.setPrimary", new { sellerId, bankAccountId });
        return ok;
    }

    public async Task<SellerWarehouseDto?> UpsertWarehouseAsync(int sellerId, UpsertSellerWarehouseRequest req, int actorUserId)
    {
        if (string.IsNullOrWhiteSpace(req.Name))         throw new ArgumentException("Warehouse name is required.");
        if (string.IsNullOrWhiteSpace(req.AddressLine1)) throw new ArgumentException("AddressLine1 is required.");
        if (string.IsNullOrWhiteSpace(req.City))         throw new ArgumentException("City is required.");
        if (string.IsNullOrWhiteSpace(req.Pincode))      throw new ArgumentException("Pincode is required.");

        var result = await repo.UpsertWarehouseAsync(sellerId, req, actorUserId);
        Audit(actorUserId, "seller.warehouse.upsert", new { sellerId, warehouseId = result?.SellerWarehouseId });
        return result;
    }

    public Task<IEnumerable<SellerWarehouseDto>> GetWarehousesAsync(int sellerId) =>
        repo.GetWarehousesAsync(sellerId);

    public async Task<VendorAgreementDto?> AcceptAgreementAsync(int sellerId, AcceptVendorAgreementRequest req, string? ip, string? ua, int actorUserId)
    {
        var version = string.IsNullOrWhiteSpace(req.Version) ? "1.0" : req.Version;
        var result = await repo.AcceptAgreementAsync(sellerId, version, ip, ua, req.DocumentUrl, actorUserId);
        Audit(actorUserId, "seller.agreement.accept", new { sellerId, version });
        return result;
    }

    public Task<VendorAgreementDto?> GetLatestAgreementAsync(int sellerId) =>
        repo.GetLatestAgreementAsync(sellerId);

    public async Task<SellerSettlementDto?> CalculateSettlementAsync(int sellerId, DateTime periodStart, DateTime periodEnd, int actorUserId)
    {
        if (periodEnd < periodStart) throw new ArgumentException("PeriodEnd must be on or after PeriodStart.");
        if (periodEnd.Date > DateTime.UtcNow.Date.AddDays(-7))
            throw new InvalidOperationException("Settlement period must end at least 7 days in the past (T+7 hold).");

        var result = await repo.CalculateSettlementAsync(sellerId, periodStart, periodEnd, actorUserId);
        Audit(actorUserId, "seller.settlement.calc", new { sellerId, settlementId = result?.SettlementId, net = result?.NetPayout });
        return result;
    }

    public Task<(IEnumerable<SellerSettlementDto> Items, int TotalCount)> ListSettlementsAsync(int sellerId, int page, int pageSize) =>
        repo.ListSettlementsAsync(sellerId, page, pageSize);

    public Task<SellerSettlementDetailDto> GetSettlementAsync(int settlementId, int sellerId) =>
        repo.GetSettlementAsync(settlementId, sellerId);

    public Task<SellerPerformanceScoreDto?> RecomputeScoreAsync(int sellerId, int windowDays = 30) =>
        repo.RecomputeScoreAsync(sellerId, DateTime.UtcNow.Date, windowDays);

    public Task<SellerPerformanceScoreDto?> GetLatestScoreAsync(int sellerId) =>
        repo.GetLatestScoreAsync(sellerId);

    public SettlementMath ComputeLineMath(decimal gross, decimal? sellerCommission, decimal defaultRate, decimal tdsRate, decimal penalty = 0)
    {
        var commission = sellerCommission ?? Math.Round(gross * defaultRate / 100m, 2);
        var tds        = Math.Round(commission * tdsRate / 100m, 2);
        var net        = gross - commission - tds - penalty;
        return new SettlementMath(gross, commission, tds, penalty, net);
    }

    private void Audit(int actorUserId, string action, object payload) =>
        log.LogInformation("audit user={Actor} action={Action} payload={@Payload}", actorUserId, action, payload);
}
