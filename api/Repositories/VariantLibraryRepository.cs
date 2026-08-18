using System.Data;
using System.Text.Json;
using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IVariantLibraryRepository
{
    Task<List<VariantAttributeDto>>          GetAttributesAsync(bool includeInactive);
    Task<List<SubCategoryVariantOptionDto>>  GetAdminOptionsAsync(int subCategoryId, bool includeInactive);
    Task<int>                                UpsertOptionAsync(VariantOptionUpsertRequest req, int adminUserId);
    Task                                     ToggleOptionAsync(int optionId, bool isActive, int adminUserId);
    Task                                     DeleteOptionAsync(int optionId, int adminUserId);
    Task                                     BulkSetAsync(VariantOptionBulkSetRequest req, int adminUserId);

    Task<List<SellerVariantOptionDto>>       GetForSellerAsync(int subCategoryId, int? productId);
    Task                                     SetDisabledOptionsAsync(int productId, int sellerId, List<int> optionIds, int currentUserId);
}

public class VariantLibraryRepository(IConfiguration config) : IVariantLibraryRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<List<VariantAttributeDto>> GetAttributesAsync(bool includeInactive)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<VariantAttributeDto>(
            "usp_Admin_VariantAttribute_GetAll",
            new { IncludeInactive = includeInactive },
            commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }

    public async Task<List<SubCategoryVariantOptionDto>> GetAdminOptionsAsync(int subCategoryId, bool includeInactive)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<SubCategoryVariantOptionDto>(
            "usp_Admin_SubCategoryOption_GetBySubCategory",
            new { SubCategoryId = subCategoryId, IncludeInactive = includeInactive },
            commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }

    public async Task<int> UpsertOptionAsync(VariantOptionUpsertRequest req, int adminUserId)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<int>(
            "usp_Admin_SubCategoryOption_Upsert",
            new
            {
                req.OptionId,
                req.SubCategoryId,
                req.AttributeId,
                req.OptionValue,
                req.OptionMetadata,
                req.SortOrder,
                AdminUserId = adminUserId,
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task ToggleOptionAsync(int optionId, bool isActive, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_SubCategoryOption_ToggleActive",
            new { OptionId = optionId, IsActive = isActive, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task DeleteOptionAsync(int optionId, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_SubCategoryOption_Delete",
            new { OptionId = optionId, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task BulkSetAsync(VariantOptionBulkSetRequest req, int adminUserId)
    {
        var json = JsonSerializer.Serialize(req.Options.Select(o => new
        {
            optionValue    = o.OptionValue,
            optionMetadata = o.OptionMetadata,
            sortOrder      = o.SortOrder,
        }));
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_SubCategoryOption_BulkSet",
            new { req.SubCategoryId, req.AttributeId, OptionsJson = json, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<List<SellerVariantOptionDto>> GetForSellerAsync(int subCategoryId, int? productId)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<SellerVariantOptionDto>(
            "usp_Catalog_SubCategoryOption_GetForSeller",
            new { SubCategoryId = subCategoryId, ProductId = productId },
            commandType: CommandType.StoredProcedure);
        return rows.ToList();
    }

    public async Task SetDisabledOptionsAsync(int productId, int sellerId, List<int> optionIds, int currentUserId)
    {
        var json = JsonSerializer.Serialize(optionIds.Select(id => new { optionId = id }));
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Seller_ProductDisabledOptions_Set",
            new { ProductId = productId, SellerId = sellerId, DisabledJson = json, CurrentUserId = currentUserId },
            commandType: CommandType.StoredProcedure);
    }
}
