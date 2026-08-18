using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface ICatalogueRepository
{
    Task<List<MegaMenuCategoryDto>> GetMegaMenuAsync();
    Task<List<BannerDto>> GetBannersAsync(int section);
    Task<List<BannerDto>> GetBannerStackAsync();
    Task<List<CmsBannerDto>> GetAllBannersAdminAsync();
    Task<int> UpsertBannerAsync(CmsBannerUpsertRequest req, int userId);
    Task<bool> DeleteBannerAsync(int bannerId, int userId);
    Task<List<StoreDto>> GetStoresAsync(string? city);
    Task<PincodeDeliveryDto?> GetPincodeDeliveryAsync(string pincode);
    Task<List<CategoryDropdownDto>> GetCategoriesAsync();
    Task<List<FeaturedSubCategoryDto>> GetFeaturedSubCategoriesAsync(int count);
    Task<List<SubCategoryDropdownDto>> GetSubCategoriesByCategoryAsync(int categoryId);
    Task<List<BrandDropdownDto>> GetBrandsAsync();
    Task<SubCategoryFormSchemaDto?> GetSubCategoryFormSchemaAsync(int subCategoryId);
}

public class CatalogueRepository(IConfiguration config) : ICatalogueRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<List<MegaMenuCategoryDto>> GetMegaMenuAsync()
    {
        using var db = Conn();
        var rows = await db.QueryAsync<MegaMenuRawDto>("sp_GetMegaMenu",
            commandType: System.Data.CommandType.StoredProcedure);

        var topMenus = new Dictionary<int, MegaMenuCategoryDto>();
        var subMenus = new Dictionary<int, MegaMenuSubCategoryDto>();

        foreach (var r in rows)
        {
            if (!topMenus.TryGetValue(r.TopMenuId, out var topMenu))
            {
                topMenu = new MegaMenuCategoryDto
                {
                    TopMenuId   = r.TopMenuId,
                    TopMenuName = r.TopMenuName,
                    TopMenuSlug = r.TopMenuSlug
                };
                topMenus[topMenu.TopMenuId] = topMenu;
            }

            if (!subMenus.TryGetValue(r.SubMenuId, out var subMenu))
            {
                subMenu = new MegaMenuSubCategoryDto
                {
                    SubMenuId   = r.SubMenuId,
                    SubMenuName = r.SubMenuName,
                    SubMenuSlug = r.SubMenuSlug,
                    SubMenuIconUrl = r.SubMenuIconUrl
                };
                subMenus[subMenu.SubMenuId] = subMenu;
                topMenu.SubCategories.Add(subMenu);
            }

            subMenu.ProductTypes.Add(new MegaMenuProductTypeDto
            {
                SubSubMenuId   = r.SubSubMenuId,
                SubSubMenuName = r.SubSubMenuName,
                SubSubMenuSlug = r.SubSubMenuSlug,
                SubSubMenuIconUrl = r.SubSubMenuIconUrl
            });
        }

        return [.. topMenus.Values];
    }

    public async Task<List<FeaturedSubCategoryDto>> GetFeaturedSubCategoriesAsync(int count)
    {
        using var db = Conn();
        var result = await db.QueryAsync<FeaturedSubCategoryDto>(
            "usp_Catalog_SubCategory_GetFeatured",
            new { Count = count },
            commandType: System.Data.CommandType.StoredProcedure);
        return [.. result];
    }

    public async Task<List<BannerDto>> GetBannersAsync(int section)
    {
        using var db = Conn();
        var result = await db.QueryAsync<BannerDto>("sp_GetBanners",
            new { Section = section },
            commandType: System.Data.CommandType.StoredProcedure);
        return [.. result];
    }

    /// <summary>One round-trip for every promotional banner (BannerType 2..7), ordered for stacking.</summary>
    public async Task<List<BannerDto>> GetBannerStackAsync()
    {
        using var db = Conn();
        var result = await db.QueryAsync<BannerDto>("sp_GetBannerStack",
            commandType: System.Data.CommandType.StoredProcedure);
        return [.. result];
    }

    public async Task<List<CmsBannerDto>> GetAllBannersAdminAsync()
    {
        using var db = Conn();
        var result = await db.QueryAsync<CmsBannerDto>("usp_CMS_Banner_GetAll",
            commandType: System.Data.CommandType.StoredProcedure);
        return [.. result];
    }

    public async Task<int> UpsertBannerAsync(CmsBannerUpsertRequest req, int userId)
    {
        using var db = Conn();
        var result = await db.QuerySingleAsync<int>("usp_CMS_Banner_Upsert",
            new
            {
                BannerId = req.BannerId,
                Title = req.Title,
                SubTitle = req.SubTitle,
                ImageUrl = req.ImageUrl,
                MobileImageUrl = req.MobileImageUrl,
                LinkUrl = req.LinkUrl,
                BannerType = req.Section,
                SortOrder = req.SortOrder,
                GapBelowPx = req.GapBelowPx,
                BackgroundColor = req.BackgroundColor,
                IsActive = req.IsActive,
                StartDate = req.StartDate,
                EndDate = req.EndDate,
                UpdatedBy = userId
            },
            commandType: System.Data.CommandType.StoredProcedure);
        return result;
    }

    public async Task<bool> DeleteBannerAsync(int bannerId, int userId)
    {
        using var db = Conn();
        try
        {
            var result = await db.QuerySingleAsync<int>("usp_CMS_Banner_Delete",
                new { BannerId = bannerId, DeletedBy = userId },
                commandType: System.Data.CommandType.StoredProcedure);
            return result > 0;
        }
        catch (SqlException ex) when (ex.Number == 50140)
        {
            return false;
        }
    }

    public async Task<List<StoreDto>> GetStoresAsync(string? city)
    {
        using var db = Conn();
        var result = await db.QueryAsync<StoreDto>("sp_GetStores",
            new { City = city },
            commandType: System.Data.CommandType.StoredProcedure);
        return [.. result];
    }

    public async Task<PincodeDeliveryDto?> GetPincodeDeliveryAsync(string pincode)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<PincodeDeliveryDto>(
            "usp_Catalog_Pincode_Get",
            new { Pincode = pincode },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<List<CategoryDropdownDto>> GetCategoriesAsync()
    {
        using var db = Conn();
        var result = await db.QueryAsync<CategoryDropdownDto>(
            "usp_Catalog_Category_GetAll",
            new { MenuId = (int?)null, IsFeaturedOnly = 0 },
            commandType: System.Data.CommandType.StoredProcedure);
        return [.. result];
    }

    public async Task<List<SubCategoryDropdownDto>> GetSubCategoriesByCategoryAsync(int categoryId)
    {
        using var db = Conn();
        var result = await db.QueryAsync<SubCategoryDropdownDto>(
            "usp_Catalog_SubCategory_GetByCategory",
            new { CategoryId = categoryId },
            commandType: System.Data.CommandType.StoredProcedure);
        return [.. result];
    }

    public async Task<List<BrandDropdownDto>> GetBrandsAsync()
    {
        using var db = Conn();
        var result = await db.QueryAsync<BrandDropdownDto>(
            "SELECT BrandId AS Id, BrandName AS Name FROM Brands WHERE IsDeleted = 0 AND IsActive = 1 ORDER BY BrandName",
            commandType: System.Data.CommandType.Text);
        return [.. result];
    }

    private sealed class FormSchemaRow
    {
        public int     SubCategoryId      { get; set; }
        public string  SubCategoryName    { get; set; } = string.Empty;
        public string? ImageAngles        { get; set; }
        public string? SizeScale          { get; set; }
        public bool    RequiresGender     { get; set; }
        public bool    RequiresDimensions { get; set; }
    }

    public async Task<SubCategoryFormSchemaDto?> GetSubCategoryFormSchemaAsync(int subCategoryId)
    {
        using var db = Conn();
        var row = await db.QuerySingleOrDefaultAsync<FormSchemaRow>(
            "usp_Catalog_SubCategory_GetFormSchema",
            new { SubCategoryId = subCategoryId },
            commandType: System.Data.CommandType.StoredProcedure);
        if (row is null) return null;

        string[] angles;
        try
        {
            angles = string.IsNullOrWhiteSpace(row.ImageAngles)
                ? new[] { "single" }
                : System.Text.Json.JsonSerializer.Deserialize<string[]>(row.ImageAngles) ?? new[] { "single" };
        }
        catch
        {
            angles = new[] { "single" };
        }

        return new SubCategoryFormSchemaDto
        {
            SubCategoryId      = row.SubCategoryId,
            SubCategoryName    = row.SubCategoryName,
            ImageAngles        = angles,
            SizeScale          = string.IsNullOrWhiteSpace(row.SizeScale) ? "none" : row.SizeScale!,
            RequiresGender     = row.RequiresGender,
            RequiresDimensions = row.RequiresDimensions,
        };
    }
}
