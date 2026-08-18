using System.Data;
using System.Text.Json;
using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IAdminCategoryRepository
{
    Task<AdminMegaMenuTreeDto> GetTreeAsync(bool includeInactive);

    Task<int>  UpsertCategoryAsync(AdminCategoryUpsertRequest req, int adminUserId);
    Task       ToggleCategoryVisibilityAsync(int categoryId, bool? isActive, bool? showInMegaMenu, int adminUserId);
    Task       ReorderCategoriesAsync(List<CategoryReorderItem> items, int adminUserId);
    Task       DeleteCategoryAsync(int categoryId, int adminUserId);

    Task<int>  UpsertSubCategoryAsync(AdminSubCategoryUpsertRequest req, int adminUserId);
    Task       ToggleSubCategoryVisibilityAsync(int subCategoryId, bool? isActive, bool? showInMegaMenu, int adminUserId);
    Task       ReorderSubCategoriesAsync(List<SubCategoryReorderItem> items, int adminUserId);
    Task       DeleteSubCategoryAsync(int subCategoryId, int adminUserId);
    Task       UpdateSubCategoryFormRulesAsync(int subCategoryId, UpdateFormRulesRequest req, int adminUserId);
}

public class AdminCategoryRepository(IConfiguration config) : IAdminCategoryRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<AdminMegaMenuTreeDto> GetTreeAsync(bool includeInactive)
    {
        using var db = Conn();
        using var multi = await db.QueryMultipleAsync(
            "usp_Admin_MegaMenu_GetTree",
            new { IncludeInactive = includeInactive },
            commandType: CommandType.StoredProcedure);

        var cats = (await multi.ReadAsync<AdminCategoryDto>()).ToList();
        var subs = (await multi.ReadAsync<AdminSubCategoryDto>()).ToList();
        return new AdminMegaMenuTreeDto { Categories = cats, SubCategories = subs };
    }

    public async Task<int> UpsertCategoryAsync(AdminCategoryUpsertRequest req, int adminUserId)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<int>(
            "usp_Admin_Category_Upsert",
            new
            {
                req.CategoryId,
                req.MenuId,
                req.CategoryName,
                req.SlugUrl,
                req.IconUrl,
                req.BannerUrl,
                req.SortOrder,
                req.IsFeatured,
                req.ShowInMegaMenu,
                req.MetaTitle,
                req.MetaDescription,
                AdminUserId = adminUserId,
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task ToggleCategoryVisibilityAsync(int categoryId, bool? isActive, bool? showInMegaMenu, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_Category_ToggleVisibility",
            new { CategoryId = categoryId, IsActive = isActive, ShowInMegaMenu = showInMegaMenu, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task ReorderCategoriesAsync(List<CategoryReorderItem> items, int adminUserId)
    {
        var json = JsonSerializer.Serialize(items.Select(i => new
        {
            categoryId = i.CategoryId,
            sortOrder  = i.SortOrder,
        }));
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_Category_Reorder",
            new { OrderJson = json, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task DeleteCategoryAsync(int categoryId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_Category_Delete",
            new { CategoryId = categoryId, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> UpsertSubCategoryAsync(AdminSubCategoryUpsertRequest req, int adminUserId)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<int>(
            "usp_Admin_SubCategory_Upsert",
            new
            {
                req.SubCategoryId,
                req.CategoryId,
                req.SubCategoryName,
                req.SlugUrl,
                req.IconUrl,
                req.SortOrder,
                req.IsFeatured,
                req.ShowInMegaMenu,
                req.MetaTitle,
                req.MetaDescription,
                AdminUserId = adminUserId,
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task ToggleSubCategoryVisibilityAsync(int subCategoryId, bool? isActive, bool? showInMegaMenu, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_SubCategory_ToggleVisibility",
            new { SubCategoryId = subCategoryId, IsActive = isActive, ShowInMegaMenu = showInMegaMenu, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task ReorderSubCategoriesAsync(List<SubCategoryReorderItem> items, int adminUserId)
    {
        var json = JsonSerializer.Serialize(items.Select(i => new
        {
            subCategoryId = i.SubCategoryId,
            sortOrder     = i.SortOrder,
        }));
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_SubCategory_Reorder",
            new { OrderJson = json, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task DeleteSubCategoryAsync(int subCategoryId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_SubCategory_Delete",
            new { SubCategoryId = subCategoryId, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task UpdateSubCategoryFormRulesAsync(int subCategoryId, UpdateFormRulesRequest req, int adminUserId)
    {
        var anglesJson = JsonSerializer.Serialize(req.ImageAngles ?? System.Array.Empty<string>());
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_SubCategory_UpdateFormRules",
            new
            {
                SubCategoryId      = subCategoryId,
                ImageAngles        = anglesJson,
                SizeScale          = string.IsNullOrWhiteSpace(req.SizeScale) ? "none" : req.SizeScale,
                req.RequiresGender,
                req.RequiresDimensions,
                AdminUserId        = adminUserId,
            },
            commandType: CommandType.StoredProcedure);
    }
}
