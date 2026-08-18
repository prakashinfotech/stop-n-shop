using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IProductService
{
    Task<PagedResult<ProductListItemDto>> GetProductsAsync(ProductQueryParams q);
    Task<ProductDetailDto?> GetProductDetailAsync(int id);
    Task<List<ProductListItemDto>> GetSimilarProductsAsync(int id);
    Task<List<ProductListItemDto>> GetRecommendedProductsAsync(string productIds);
    Task<List<ProductListItemDto>> GetTrendingProductsAsync(int windowDays = 7, int limit = 12);
    Task<OffersMasterDto> GetOffersMasterAsync();
}

public class ProductService(IProductRepository repo) : IProductService
{
    public async Task<PagedResult<ProductListItemDto>> GetProductsAsync(ProductQueryParams q)
    {
        var (items, total) = await repo.GetProductsAsync(q);
        return new PagedResult<ProductListItemDto>
        {
            Items      = items,
            TotalCount = total,
            PageNo     = q.PageNo,
            PageSize   = q.PageSize
        };
    }

    public async Task<ProductDetailDto?> GetProductDetailAsync(int id)
    {
        var dto = await repo.GetProductDetailAsync(id);
        if (dto is null) return null;
        ApplyExtendedDefaults(dto);
        return dto;
    }

    /// <summary>
    /// Sensible defaults for legacy products that don't have the extended detail columns filled in.
    /// Applied at read-time so a single line removal here fully reverts the behaviour — no SQL backfill.
    /// </summary>
    private static void ApplyExtendedDefaults(ProductDetailDto dto)
    {
        dto.Material         ??= "Standard Fabric";
        dto.CareInstructions ??= "Machine Wash";
        dto.FitType          ??= "Regular Fit";
        dto.DeliveryInfo     ??= "Delivery available based on pincode";
        if (dto.ReturnPolicyDays <= 0) dto.ReturnPolicyDays = 14;
        if (dto.Seller is not null && string.IsNullOrWhiteSpace(dto.Seller.Description))
            dto.Seller.Description = "StopNShop Verified Seller";
    }
    public Task<List<ProductListItemDto>> GetSimilarProductsAsync(int id) => repo.GetSimilarProductsAsync(id);
    public Task<List<ProductListItemDto>> GetRecommendedProductsAsync(string productIds) =>
        repo.GetRecommendedProductsAsync(productIds);
    public Task<List<ProductListItemDto>> GetTrendingProductsAsync(int windowDays = 7, int limit = 12) =>
        repo.GetTrendingProductsAsync(windowDays, limit);
    public Task<OffersMasterDto> GetOffersMasterAsync() => repo.GetOffersMasterAsync();
}
