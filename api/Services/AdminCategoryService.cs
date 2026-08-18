using System.Text.Json;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IAdminCategoryService
{
    Task<AdminMegaMenuTreeDto> GetTreeAsync(bool includeInactive);

    Task<int> UpsertCategoryAsync(AdminCategoryUpsertRequest req, int adminUserId, string? ip);
    Task      ToggleCategoryVisibilityAsync(int categoryId, ToggleVisibilityRequest req, int adminUserId, string? ip);
    Task      ReorderCategoriesAsync(CategoryReorderRequest req, int adminUserId, string? ip);
    Task      DeleteCategoryAsync(int categoryId, int adminUserId, string? ip);

    Task<int> UpsertSubCategoryAsync(AdminSubCategoryUpsertRequest req, int adminUserId, string? ip);
    Task      ToggleSubCategoryVisibilityAsync(int subCategoryId, ToggleVisibilityRequest req, int adminUserId, string? ip);
    Task      ReorderSubCategoriesAsync(SubCategoryReorderRequest req, int adminUserId, string? ip);
    Task      DeleteSubCategoryAsync(int subCategoryId, int adminUserId, string? ip);
    Task      UpdateSubCategoryFormRulesAsync(int subCategoryId, UpdateFormRulesRequest req, int adminUserId, string? ip);
}

public class AdminCategoryService(IAdminCategoryRepository repo, IAdminRepository adminRepo)
    : IAdminCategoryService
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

    public Task<AdminMegaMenuTreeDto> GetTreeAsync(bool includeInactive) =>
        repo.GetTreeAsync(includeInactive);

    public async Task<int> UpsertCategoryAsync(AdminCategoryUpsertRequest req, int adminUserId, string? ip)
    {
        var id = await repo.UpsertCategoryAsync(req, adminUserId);
        var verb = req.CategoryId is null or 0 ? "CATEGORY_CREATE" : "CATEGORY_UPDATE";
        await AuditAsync("Categories", id, verb, req, adminUserId, ip);
        return id;
    }

    public async Task ToggleCategoryVisibilityAsync(int categoryId, ToggleVisibilityRequest req, int adminUserId, string? ip)
    {
        await repo.ToggleCategoryVisibilityAsync(categoryId, req.IsActive, req.ShowInMegaMenu, adminUserId);
        await AuditAsync("Categories", categoryId, "CATEGORY_TOGGLE", req, adminUserId, ip);
    }

    public async Task ReorderCategoriesAsync(CategoryReorderRequest req, int adminUserId, string? ip)
    {
        await repo.ReorderCategoriesAsync(req.Items, adminUserId);
        await AuditAsync("Categories", 0, "CATEGORY_REORDER", req, adminUserId, ip);
    }

    public async Task DeleteCategoryAsync(int categoryId, int adminUserId, string? ip)
    {
        await repo.DeleteCategoryAsync(categoryId, adminUserId);
        await AuditAsync("Categories", categoryId, "CATEGORY_DELETE", null, adminUserId, ip);
    }

    public async Task<int> UpsertSubCategoryAsync(AdminSubCategoryUpsertRequest req, int adminUserId, string? ip)
    {
        var id = await repo.UpsertSubCategoryAsync(req, adminUserId);
        var verb = req.SubCategoryId is null or 0 ? "SUBCATEGORY_CREATE" : "SUBCATEGORY_UPDATE";
        await AuditAsync("SubCategories", id, verb, req, adminUserId, ip);
        return id;
    }

    public async Task ToggleSubCategoryVisibilityAsync(int subCategoryId, ToggleVisibilityRequest req, int adminUserId, string? ip)
    {
        await repo.ToggleSubCategoryVisibilityAsync(subCategoryId, req.IsActive, req.ShowInMegaMenu, adminUserId);
        await AuditAsync("SubCategories", subCategoryId, "SUBCATEGORY_TOGGLE", req, adminUserId, ip);
    }

    public async Task ReorderSubCategoriesAsync(SubCategoryReorderRequest req, int adminUserId, string? ip)
    {
        await repo.ReorderSubCategoriesAsync(req.Items, adminUserId);
        await AuditAsync("SubCategories", 0, "SUBCATEGORY_REORDER", req, adminUserId, ip);
    }

    public async Task DeleteSubCategoryAsync(int subCategoryId, int adminUserId, string? ip)
    {
        await repo.DeleteSubCategoryAsync(subCategoryId, adminUserId);
        await AuditAsync("SubCategories", subCategoryId, "SUBCATEGORY_DELETE", null, adminUserId, ip);
    }

    public async Task UpdateSubCategoryFormRulesAsync(int subCategoryId, UpdateFormRulesRequest req, int adminUserId, string? ip)
    {
        await repo.UpdateSubCategoryFormRulesAsync(subCategoryId, req, adminUserId);
        await AuditAsync("SubCategories", subCategoryId, "SUBCATEGORY_FORM_RULES", req, adminUserId, ip);
    }
}
