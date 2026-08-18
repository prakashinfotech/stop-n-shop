using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface ICatalogueService
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

public class CatalogueService(ICatalogueRepository repo) : ICatalogueService
{
    public Task<List<MegaMenuCategoryDto>> GetMegaMenuAsync() => repo.GetMegaMenuAsync();
    public Task<List<BannerDto>> GetBannersAsync(int section) => repo.GetBannersAsync(section);
    public Task<List<BannerDto>> GetBannerStackAsync() => repo.GetBannerStackAsync();
    public Task<List<CmsBannerDto>> GetAllBannersAdminAsync() => repo.GetAllBannersAdminAsync();
    public Task<int> UpsertBannerAsync(CmsBannerUpsertRequest req, int userId) => repo.UpsertBannerAsync(req, userId);
    public Task<bool> DeleteBannerAsync(int bannerId, int userId) => repo.DeleteBannerAsync(bannerId, userId);
    public Task<List<StoreDto>> GetStoresAsync(string? city) => repo.GetStoresAsync(city);
    public Task<PincodeDeliveryDto?> GetPincodeDeliveryAsync(string pincode) => repo.GetPincodeDeliveryAsync(pincode);
    public Task<List<CategoryDropdownDto>> GetCategoriesAsync() => repo.GetCategoriesAsync();
    public Task<List<FeaturedSubCategoryDto>> GetFeaturedSubCategoriesAsync(int count) =>
        repo.GetFeaturedSubCategoriesAsync(count);
    public Task<List<SubCategoryDropdownDto>> GetSubCategoriesByCategoryAsync(int categoryId) => repo.GetSubCategoriesByCategoryAsync(categoryId);
    public Task<List<BrandDropdownDto>> GetBrandsAsync() => repo.GetBrandsAsync();
    public Task<SubCategoryFormSchemaDto?> GetSubCategoryFormSchemaAsync(int subCategoryId) =>
        repo.GetSubCategoryFormSchemaAsync(subCategoryId);
}
