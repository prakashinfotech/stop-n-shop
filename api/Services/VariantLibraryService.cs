using System.Text.Json;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IVariantLibraryService
{
    Task<List<VariantAttributeDto>>         GetAttributesAsync();
    Task<List<SubCategoryVariantOptionDto>> GetAdminOptionsAsync(int subCategoryId);
    Task<int>                               UpsertOptionAsync(VariantOptionUpsertRequest req, int adminUserId, string? ip);
    Task                                    ToggleOptionAsync(int optionId, bool isActive, int adminUserId, string? ip);
    Task                                    DeleteOptionAsync(int optionId, int adminUserId, string? ip);
    Task                                    BulkSetAsync(VariantOptionBulkSetRequest req, int adminUserId, string? ip);

    Task<List<SellerVariantOptionDto>>      GetForSellerAsync(int subCategoryId, int? productId);
    Task                                    SetDisabledOptionsAsync(int productId, int sellerId, SetDisabledOptionsRequest req, int currentUserId);
}

public class VariantLibraryService(IVariantLibraryRepository repo, IAdminRepository adminRepo)
    : IVariantLibraryService
{
    private static readonly JsonSerializerOptions JsonOpts = new() { WriteIndented = false };

    private Task AuditAsync(string table, int recordId, string verb, object? payload, int adminUserId, string? ip)
        => adminRepo.WriteAuditAsync(
            tableName: table,
            recordId:  recordId,
            action:    "UPDATE",
            oldValues: null,
            newValues: JsonSerializer.Serialize(new { verb, data = payload }, JsonOpts),
            changedBy: adminUserId,
            ipAddress: ip);

    public Task<List<VariantAttributeDto>>         GetAttributesAsync()             => repo.GetAttributesAsync(true);
    public Task<List<SubCategoryVariantOptionDto>> GetAdminOptionsAsync(int subId)  => repo.GetAdminOptionsAsync(subId, includeInactive: true);

    public async Task<int> UpsertOptionAsync(VariantOptionUpsertRequest req, int adminUserId, string? ip)
    {
        var id = await repo.UpsertOptionAsync(req, adminUserId);
        var verb = req.OptionId is null or 0 ? "VARIANT_OPTION_CREATE" : "VARIANT_OPTION_UPDATE";
        await AuditAsync("SubCategoryVariantOptions", id, verb, req, adminUserId, ip);
        return id;
    }

    public async Task ToggleOptionAsync(int optionId, bool isActive, int adminUserId, string? ip)
    {
        await repo.ToggleOptionAsync(optionId, isActive, adminUserId);
        await AuditAsync("SubCategoryVariantOptions", optionId, "VARIANT_OPTION_TOGGLE", new { isActive }, adminUserId, ip);
    }

    public async Task DeleteOptionAsync(int optionId, int adminUserId, string? ip)
    {
        await repo.DeleteOptionAsync(optionId, adminUserId);
        await AuditAsync("SubCategoryVariantOptions", optionId, "VARIANT_OPTION_DELETE", null, adminUserId, ip);
    }

    public async Task BulkSetAsync(VariantOptionBulkSetRequest req, int adminUserId, string? ip)
    {
        await repo.BulkSetAsync(req, adminUserId);
        await AuditAsync("SubCategoryVariantOptions", req.SubCategoryId, "VARIANT_OPTION_BULK_SET", req, adminUserId, ip);
    }

    public Task<List<SellerVariantOptionDto>> GetForSellerAsync(int subCategoryId, int? productId) =>
        repo.GetForSellerAsync(subCategoryId, productId);

    public Task SetDisabledOptionsAsync(int productId, int sellerId, SetDisabledOptionsRequest req, int currentUserId) =>
        repo.SetDisabledOptionsAsync(productId, sellerId, req.OptionIds ?? new List<int>(), currentUserId);
}
