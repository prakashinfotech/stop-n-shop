using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface ISellerProductService
{
    Task<PagedResult<SellerProductListDto>> GetProductsAsync(int sellerId, string? approvalStatus, int page, int pageSize);
    Task<SellerProductDetailDto?> GetDetailAsync(int productId, int sellerId);
    Task<SellerProductDetailDto> CreateAsync(int sellerId, CreateSellerProductRequest req);
    Task UpdateAsync(int productId, int sellerId, UpdateSellerProductRequest req);
    Task DeleteAsync(int productId, int sellerId);
    Task UpdateInventoryAsync(int productId, int sellerId, UpdateInventoryRequest req);
    Task<List<SellerInventoryDto>> GetInventoryAsync(int sellerId);
    Task<List<SellerInventoryDto>> GetLowStockItemsAsync(int sellerId);
}

public class SellerProductService(ISellerProductRepository repo) : ISellerProductService
{
    public Task<PagedResult<SellerProductListDto>> GetProductsAsync(int sellerId, string? approvalStatus, int page, int pageSize) =>
        repo.GetProductsAsync(sellerId, approvalStatus, page, pageSize);

    public Task<SellerProductDetailDto?> GetDetailAsync(int productId, int sellerId) =>
        repo.GetDetailAsync(sellerId, productId);

    public async Task<SellerProductDetailDto> CreateAsync(int sellerId, CreateSellerProductRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name))
            throw new ArgumentException("Product name is required.");
        if (req.CategoryId <= 0)
            throw new ArgumentException("A valid Category is required.");
        if (req.MRP <= 0 || req.SellingPrice <= 0)
            throw new ArgumentException("MRP and SellingPrice must be greater than zero.");

        var productId = await repo.CreateProductAsync(sellerId, req);

        // Prefer slot-aware Images payload; fall back to legacy ImageUrls.
        var imageList = NormalizeImagePayload(req.Images, req.ImageUrls);
        for (var i = 0; i < imageList.Count; i++)
        {
            var (url, slot) = imageList[i];
            await repo.AddProductImageAsync(productId, url, isPrimary: i == 0, sortOrder: i, slot: slot);
        }

        var skuBase = $"V{productId:D6}";

        if (req.VariantMatrix is { Count: > 0 })
        {
            // New path: per-cell quantities from the seller's matrix UI.
            await WriteVariantMatrixAsync(productId, sellerId, req.VariantMatrix, req.LowStockThreshold, skuBase);
        }
        else
        {
            var colors = (req.Colors ?? []).Where(c => !string.IsNullOrWhiteSpace(c)).Select(c => c.Trim()).ToList();
            var sizes  = (req.Sizes  ?? []).Where(s => !string.IsNullOrWhiteSpace(s)).Select(s => s.Trim()).ToList();
            var combos = BuildVariantCombos(colors, sizes);

            if (combos.Count == 0)
            {
                // No colors/sizes — create a single default variant so stock is preserved.
                await repo.AddProductVariantAsync(productId, null, null, $"{skuBase}-DEFAULT", req.StockQuantity, req.LowStockThreshold, sellerId);
            }
            else
            {
                // Legacy path: each (color, size) variant carries the same uniform stock.
                var idx = 0;
                foreach (var (color, size) in combos)
                {
                    var suffix = $"{Sanitize(color)}{Sanitize(size)}{idx++:D2}";
                    var variantSku = $"{skuBase}-{suffix}";
                    await repo.AddProductVariantAsync(productId, color, size, variantSku, req.StockQuantity, req.LowStockThreshold, sellerId);
                }
            }
        }

        var product = await repo.GetDetailAsync(sellerId, productId);
        return product ?? throw new InvalidOperationException("Product created but could not be retrieved.");
    }

    public async Task UpdateAsync(int productId, int sellerId, UpdateSellerProductRequest req)
    {
        await repo.UpdateProductAsync(sellerId, productId, req);

        // When the client sends an ImageUrls list, treat it as authoritative —
        // soft-delete existing rows and insert the new set (first = primary).
        // null/missing means "don't touch images"; empty list means "clear all".
        // Slot-aware Images wins; legacy ImageUrls still supported.
        if (req.Images is not null)
        {
            var list = req.Images
                .Where(p => !string.IsNullOrWhiteSpace(p.Url))
                .Select(p => (p.Url, p.Slot))
                .ToList();
            await repo.ReplaceProductImagesAsync(productId, list);
        }
        else if (req.ImageUrls is not null)
        {
            var list = req.ImageUrls
                .Where(u => !string.IsNullOrWhiteSpace(u))
                .Select(u => (Url: u, Slot: (string?)null))
                .ToList();
            await repo.ReplaceProductImagesAsync(productId, list);
        }

        // Matrix path wins. Otherwise legacy Colors/Sizes rebuild stays.
        if (req.VariantMatrix is { Count: > 0 })
        {
            await repo.DeleteVariantsByProductAsync(sellerId, productId);
            // Append a per-update suffix because soft-deleted variant SKUs still hold the UNIQUE constraint.
            var skuBase = $"V{productId:D6}-U{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";
            await WriteVariantMatrixAsync(productId, sellerId, req.VariantMatrix, req.LowStockThreshold ?? 10, skuBase);
        }
        else
        {
            var hasColors = req.Colors is { Count: > 0 };
            var hasSizes  = req.Sizes  is { Count: > 0 };
            if (hasColors || hasSizes)
            {
                await repo.DeleteVariantsByProductAsync(sellerId, productId);

                var colors = (req.Colors ?? []).Where(c => !string.IsNullOrWhiteSpace(c)).Select(c => c.Trim()).ToList();
                var sizes  = (req.Sizes  ?? []).Where(s => !string.IsNullOrWhiteSpace(s)).Select(s => s.Trim()).ToList();
                var combos = BuildVariantCombos(colors, sizes);

                var skuBase    = $"V{productId:D6}-U{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}";
                var totalStock = req.StockQuantity ?? 0;
                var low        = req.LowStockThreshold ?? 10;

                if (combos.Count == 0)
                {
                    await repo.AddProductVariantAsync(productId, null, null, $"{skuBase}-DEFAULT", totalStock, low, sellerId);
                }
                else
                {
                    var idx = 0;
                    foreach (var (color, size) in combos)
                    {
                        var suffix = $"{Sanitize(color)}{Sanitize(size)}{idx++:D2}";
                        var variantSku = $"{skuBase}-{suffix}";
                        await repo.AddProductVariantAsync(productId, color, size, variantSku, totalStock, low, sellerId);
                    }
                }
            }
        }
    }

    private async Task WriteVariantMatrixAsync(
        int productId, int sellerId, List<ProductVariantCell> cells, int lowStockThreshold, string skuBase)
    {
        var seenSkus = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var idx = 0;
        foreach (var cell in cells)
        {
            if (cell.StockQuantity < 0) continue;

            var color = string.IsNullOrWhiteSpace(cell.Color) ? null : cell.Color.Trim();
            var size  = string.IsNullOrWhiteSpace(cell.Size)  ? null : cell.Size.Trim();

            var sku = !string.IsNullOrWhiteSpace(cell.VariantSku)
                ? cell.VariantSku!.Trim()
                : $"{skuBase}-{Sanitize(color)}{Sanitize(size)}{idx:D2}";
            // De-dupe within this batch — UNIQUE constraint on VariantSku would otherwise blow up.
            if (!seenSkus.Add(sku)) { idx++; continue; }

            await repo.AddProductVariantAsync(productId, color, size, sku, cell.StockQuantity, lowStockThreshold, sellerId, cell.AdditionalPrice);
            idx++;
        }
    }

    public Task DeleteAsync(int productId, int sellerId) =>
        repo.DeleteProductAsync(sellerId, productId);

    public Task UpdateInventoryAsync(int productId, int sellerId, UpdateInventoryRequest req) =>
        repo.UpdateInventoryAsync(sellerId, productId, req);

    public Task<List<SellerInventoryDto>> GetInventoryAsync(int sellerId) =>
        repo.GetInventoryAsync(sellerId);

    public Task<List<SellerInventoryDto>> GetLowStockItemsAsync(int sellerId) =>
        repo.GetLowStockItemsAsync(sellerId);

    private static List<(string Url, string? Slot)> NormalizeImagePayload(
        List<ProductImagePayload>? images, List<string>? legacyUrls)
    {
        if (images is { Count: > 0 })
            return images
                .Where(p => !string.IsNullOrWhiteSpace(p.Url))
                .Select(p => (p.Url, p.Slot))
                .ToList();
        if (legacyUrls is { Count: > 0 })
            return legacyUrls
                .Where(u => !string.IsNullOrWhiteSpace(u))
                .Select(u => (Url: u, Slot: (string?)null))
                .ToList();
        return new List<(string Url, string? Slot)>();
    }

    private static List<(string? Color, string? Size)> BuildVariantCombos(List<string> colors, List<string> sizes)
    {
        if (colors.Count == 0 && sizes.Count == 0) return [];
        if (colors.Count > 0 && sizes.Count > 0)
            return (from c in colors from s in sizes select ((string?)c, (string?)s)).ToList();
        if (colors.Count > 0) return colors.Select(c => ((string?)c, (string?)null)).ToList();
        return sizes.Select(s => ((string?)null, (string?)s)).ToList();
    }

    private static string Sanitize(string? part) =>
        string.IsNullOrWhiteSpace(part) ? string.Empty : new string(part.Where(char.IsLetterOrDigit).ToArray()).ToUpperInvariant();
}
