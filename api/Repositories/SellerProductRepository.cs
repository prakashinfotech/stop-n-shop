using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface ISellerProductRepository
{
    Task<int> CreateProductAsync(int sellerId, CreateSellerProductRequest req);
    Task AddProductImageAsync(int productId, string imageUrl, bool isPrimary, int sortOrder, string? slot = null);
    Task ReplaceProductImagesAsync(int productId, IReadOnlyList<(string Url, string? Slot)> images);
    Task AddProductVariantAsync(int productId, string? color, string? size, string variantSku, int stockQuantity, int lowStockThreshold, int sellerId, decimal additionalPrice = 0m);
    Task<PagedResult<SellerProductListDto>> GetProductsAsync(int sellerId, string? approvalStatus, int page, int pageSize);
    Task<SellerProductDetailDto?> GetDetailAsync(int sellerId, int productId);
    Task UpdateProductAsync(int sellerId, int productId, UpdateSellerProductRequest req);
    Task DeleteProductAsync(int sellerId, int productId);
    Task DeleteVariantsByProductAsync(int sellerId, int productId);
    Task UpdateInventoryAsync(int sellerId, int productId, UpdateInventoryRequest req);
    Task<List<SellerInventoryDto>> GetInventoryAsync(int sellerId);
    Task<List<SellerInventoryDto>> GetLowStockItemsAsync(int sellerId);
}

public class SellerProductRepository(IConfiguration config) : ISellerProductRepository
{
    private SqlConnection Conn() =>
        new(config.GetConnectionString("ShopNShop"));

    public async Task<int> CreateProductAsync(int sellerId, CreateSellerProductRequest req)
    {
        using var db = Conn();

        var slug = Slugify(req.Name) + "-" + DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var sku  = "SKU-" + Guid.NewGuid().ToString("N")[..8].ToUpper();

        var productId = await db.QuerySingleAsync<int>(
            "usp_Seller_Product_Create",
            new
            {
                SellerId         = sellerId,
                BrandId          = req.BrandId ?? 1,
                CategoryId       = req.CategoryId,
                SubCategoryId    = req.SubCategoryId == 0 ? (int?)null : req.SubCategoryId,
                GenderTypeId     = MapGender(req.Gender),
                ProductName      = req.Name,
                ShortDescription = req.Description,
                LongDescription  = (string?)null,
                Sku              = sku,
                SlugUrl          = slug,
                MRP              = req.MRP,
                SellingPrice     = req.SellingPrice,
                CostPrice        = req.CostPrice,
                Tags             = (req.Tags != null && req.Tags.Count > 0) ? string.Join(",", req.Tags) : null,
                Material         = req.Material,
                CareInstructions = req.CareInstructions,
                FitType          = req.FitType,
                CountryOfOrigin  = req.CountryOfOrigin,
                WarrantyInfo     = req.WarrantyInfo,
                DeliveryInfo     = req.DeliveryInfo,
                LengthCm         = req.LengthCm,
                WidthCm          = req.WidthCm,
                HeightCm         = req.HeightCm,
                WeightGm         = req.WeightGm,
                CreatedBy        = sellerId
            },
            commandType: System.Data.CommandType.StoredProcedure);

        await UpsertSpecsAsync(productId, req.Specifications);

        return productId;
    }

    private async Task UpsertSpecsAsync(int productId, List<ProductSpecDto>? specs)
    {
        if (specs is null || specs.Count == 0) return;
        using var db = Conn();
        var sortOrder = 0;
        foreach (var spec in specs)
        {
            if (string.IsNullOrWhiteSpace(spec.Key) || string.IsNullOrWhiteSpace(spec.Value)) continue;
            await db.ExecuteAsync(
                "usp_Catalog_ProductSpec_Upsert",
                new
                {
                    ProductId = productId,
                    SpecKey   = spec.Key.Trim(),
                    SpecValue = spec.Value.Trim(),
                    SortOrder = sortOrder++
                },
                commandType: System.Data.CommandType.StoredProcedure);
        }
    }

    public async Task AddProductImageAsync(int productId, string imageUrl, bool isPrimary, int sortOrder, string? slot = null)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Seller_ProductImage_Add",
            new
            {
                ProductId = productId,
                ImageUrl  = imageUrl,
                IsPrimary = isPrimary,
                SortOrder = sortOrder,
                ImageSlot = slot
            },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    private static byte? MapGender(string? gender)
    {
        if (string.IsNullOrWhiteSpace(gender)) return null;
        return gender.Trim().ToLowerInvariant() switch
        {
            "men" or "male" or "m"             => (byte)1,
            "women" or "female" or "f" or "w"  => (byte)2,
            "kids" or "kid" or "k"             => (byte)3,
            "unisex" or "u"                    => (byte)4,
            "beauty"                           => (byte)5,
            "all"                              => (byte)6,
            _ when byte.TryParse(gender, out var b) => b,
            _ => null,
        };
    }

    /// <summary>
    /// Soft-delete every current image row for the product and insert the
    /// new URLs in order (first one marked primary). Used by the seller
    /// Edit flow so a re-uploaded image set replaces the old set instead
    /// of appending.
    /// </summary>
    public async Task ReplaceProductImagesAsync(int productId, IReadOnlyList<(string Url, string? Slot)> images)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "UPDATE [dbo].[ProductImages] SET [IsDeleted] = 1, [UpdatedAt] = GETUTCDATE() WHERE [ProductId] = @ProductId AND [IsDeleted] = 0;",
            new { ProductId = productId },
            commandType: System.Data.CommandType.Text);

        for (var i = 0; i < images.Count; i++)
        {
            var (url, slot) = images[i];
            if (string.IsNullOrWhiteSpace(url)) continue;
            await db.ExecuteAsync(
                "usp_Seller_ProductImage_Add",
                new { ProductId = productId, ImageUrl = url, IsPrimary = i == 0, SortOrder = i, ImageSlot = slot },
                commandType: System.Data.CommandType.StoredProcedure);
        }
    }

    public async Task AddProductVariantAsync(int productId, string? color, string? size, string variantSku, int stockQuantity, int lowStockThreshold, int sellerId, decimal additionalPrice = 0m)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Seller_ProductVariant_Add",
            new
            {
                ProductId         = productId,
                Color             = color,
                Size              = size,
                VariantSku        = variantSku,
                StockQuantity     = stockQuantity,
                LowStockThreshold = lowStockThreshold,
                AdditionalPrice   = additionalPrice,
                CreatedBy         = sellerId
            },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<PagedResult<SellerProductListDto>> GetProductsAsync(int sellerId, string? approvalStatus, int page, int pageSize)
    {
        using var db = Conn();

        // Convert string status to TINYINT: Pending=1, Approved=2, Rejected=3
        byte? statusByte = approvalStatus?.ToLower() switch
        {
            "pending"  => 1,
            "approved" => 2,
            "rejected" => 3,
            _          => null
        };

        var rows = await db.QueryAsync<ProductListRow>(
            "usp_Seller_Product_GetAll",
            new
            {
                SellerId       = sellerId,
                ApprovalStatus = statusByte,
                PageNumber     = page,
                PageSize       = pageSize
            },
            commandType: System.Data.CommandType.StoredProcedure);

        var list = rows.ToList();

        return new PagedResult<SellerProductListDto>
        {
            Items      = list.Cast<SellerProductListDto>().ToList(),
            TotalCount = list.Count > 0 ? list[0].TotalCount : 0,
            PageNo     = page,
            PageSize   = pageSize
        };
    }

    private sealed class ProductListRow : SellerProductListDto
    {
        public int TotalCount { get; set; }
    }

    public async Task<SellerProductDetailDto?> GetDetailAsync(int sellerId, int productId)
    {
        using var db = Conn();

        using var multi = await db.QueryMultipleAsync(
            "usp_Catalog_Product_GetById",
            new { ProductId = productId },
            commandType: System.Data.CommandType.StoredProcedure);

        var row = await multi.ReadSingleOrDefaultAsync<ProductRow>();
        if (row is null) return null;

        // Hide products that belong to other sellers — same as a 404 to the caller.
        if (row.SellerId != sellerId) return null;

        var variants = (await multi.ReadAsync<VariantRow>()).ToList();
        var images   = (await multi.ReadAsync<ImageRow>()).ToList();
        var specs    = (await multi.ReadAsync<SpecRow>()).ToList();

        var product = new SellerProductDetailDto
        {
            Id            = row.ProductId,
            BrandId       = row.BrandId,
            BrandName     = row.BrandName,
            CategoryId    = row.CategoryId,
            SubCategoryId = row.SubCategoryId,
            Name          = row.ProductName,
            Description   = row.ShortDescription,
            MRP           = row.MRP,
            SellingPrice  = row.SellingPrice,
            CostPrice     = row.CostPrice,
            DiscountPct   = row.MRP > 0 ? Math.Round((row.MRP - row.SellingPrice) * 100m / row.MRP, 1) : 0,
            Gender        = row.GenderType,
            IsApproved    = row.ApprovalStatus == 2,
            IsActive      = true,
            Tags          = string.IsNullOrWhiteSpace(row.Tags)
                                ? []
                                : row.Tags.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).ToList(),
            Material         = row.Material,
            CareInstructions = row.CareInstructions,
            FitType          = row.FitType,
            CountryOfOrigin  = row.CountryOfOrigin,
            WarrantyInfo     = row.WarrantyInfo,
            DeliveryInfo     = row.DeliveryInfo,
            Specifications   = specs.Select(s => new ProductSpecDto { Key = s.SpecKey, Value = s.SpecValue }).ToList(),
        };

        product.ImageUrls = images
            .OrderBy(i => i.SortOrder)
            .Select(i => i.ImageUrl)
            .Where(u => !string.IsNullOrWhiteSpace(u))
            .ToList();

        product.Colors = variants
            .Where(v => !string.IsNullOrWhiteSpace(v.Color))
            .Select(v => v.Color!)
            .Distinct()
            .Select(c => new ProductColorDto { ColorName = c })
            .ToList();

        product.Sizes = variants
            .Where(v => !string.IsNullOrWhiteSpace(v.Size))
            .Select(v => v.Size!)
            .Distinct()
            .Select(s => new ProductSizeDto { SizeLabel = s, StockQuantity = variants.Where(x => x.Size == s).Sum(x => x.StockQuantity) })
            .ToList();

        product.StockQuantity     = variants.Sum(v => v.StockQuantity);
        product.LowStockThreshold = variants.Count > 0 ? variants.Min(v => v.LowStockThreshold) : 10;

        product.Variants = variants
            .Select(v => new ProductVariantCell
            {
                Color           = v.Color,
                Size            = v.Size,
                StockQuantity   = v.StockQuantity,
                AdditionalPrice = v.AdditionalPrice,
                VariantSku      = v.VariantSku,
            })
            .ToList();

        return product;
    }

    private sealed class ProductRow
    {
        public int ProductId { get; set; }
        public int SellerId { get; set; }
        public int? BrandId { get; set; }
        public string? BrandName { get; set; }
        public int CategoryId { get; set; }
        public int SubCategoryId { get; set; }
        public string ProductName { get; set; } = string.Empty;
        public string? ShortDescription { get; set; }
        public decimal MRP { get; set; }
        public decimal SellingPrice { get; set; }
        public decimal? CostPrice { get; set; }
        public string? Tags { get; set; }
        public string? GenderType { get; set; }
        public byte ApprovalStatus { get; set; }
        public string? Material { get; set; }
        public string? CareInstructions { get; set; }
        public string? FitType { get; set; }
        public string? CountryOfOrigin { get; set; }
        public string? WarrantyInfo { get; set; }
        public string? DeliveryInfo { get; set; }
    }

    private sealed class SpecRow
    {
        public string SpecKey { get; set; } = string.Empty;
        public string SpecValue { get; set; } = string.Empty;
        public int SortOrder { get; set; }
    }

    private sealed class VariantRow
    {
        public string? Color { get; set; }
        public string? Size { get; set; }
        public int StockQuantity { get; set; }
        public int LowStockThreshold { get; set; }
        public decimal AdditionalPrice { get; set; }
        public string? VariantSku { get; set; }
    }

    private sealed class ImageRow
    {
        public int SortOrder { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
    }

    public async Task UpdateProductAsync(int sellerId, int productId, UpdateSellerProductRequest req)
    {
        using var db = Conn();

        // Fetch SKU + SlugUrl + current fallbacks (not editable from UI)
        var current = await db.QuerySingleOrDefaultAsync<UpdateFallbackRow>(
            "usp_Catalog_Product_GetById",
            new { ProductId = productId },
            commandType: System.Data.CommandType.StoredProcedure);

        if (current is null) throw new Exception("Product not found.");

        await db.ExecuteAsync(
            "usp_Catalog_Product_Update",
            new
            {
                ProductId        = productId,
                ProductName      = req.Name ?? current.ProductName,
                ShortDescription = req.Description,
                LongDescription  = (string?)null,
                Sku              = current.Sku,
                SlugUrl          = current.SlugUrl,
                MRP              = req.MRP ?? current.MRP,
                SellingPrice     = req.SellingPrice ?? current.SellingPrice,
                CostPrice        = req.CostPrice,
                CategoryId       = req.CategoryId ?? current.CategoryId,
                // If the client sent a CategoryId, trust its SubCategoryId verbatim (may be null
                // when the new category has no subcategories). Falling back to current.SubCategoryId
                // here would silently keep a sub that belongs to the OLD category.
                SubCategoryId    = (object?)(req.CategoryId.HasValue ? req.SubCategoryId : (req.SubCategoryId ?? current.SubCategoryId)),
                BrandId          = req.BrandId ?? current.BrandId,
                GenderTypeId     = (object?)MapGender(req.Gender),
                Tags             = (req.Tags != null && req.Tags.Count > 0) ? string.Join(",", req.Tags) : null,
                IsFeatured       = false,
                Material         = req.Material,
                CareInstructions = req.CareInstructions,
                FitType          = req.FitType,
                CountryOfOrigin  = req.CountryOfOrigin,
                WarrantyInfo     = req.WarrantyInfo,
                DeliveryInfo     = req.DeliveryInfo,
                LengthCm         = req.LengthCm,
                WidthCm          = req.WidthCm,
                HeightCm         = req.HeightCm,
                WeightGm         = req.WeightGm,
                UpdatedBy        = sellerId
            },
            commandType: System.Data.CommandType.StoredProcedure);

        await UpsertSpecsAsync(productId, req.Specifications);
    }

    private sealed class UpdateFallbackRow
    {
        public string ProductName { get; set; } = string.Empty;
        public string Sku { get; set; } = string.Empty;
        public string SlugUrl { get; set; } = string.Empty;
        public decimal MRP { get; set; }
        public decimal SellingPrice { get; set; }
        public int CategoryId { get; set; }
        public int? SubCategoryId { get; set; }
        public int BrandId { get; set; }
    }

    public async Task DeleteVariantsByProductAsync(int sellerId, int productId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Seller_ProductVariant_DeleteByProduct",
            new { ProductId = productId, SellerId = sellerId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task DeleteProductAsync(int sellerId, int productId)
    {
        using var db = Conn();

        await db.ExecuteAsync(
            "UPDATE Products SET IsDeleted = 1, UpdatedAt = GETUTCDATE() WHERE ProductId = @ProductId AND SellerId = @SellerId",
            new { ProductId = productId, SellerId = sellerId },
            commandType: System.Data.CommandType.Text);
    }

    public async Task UpdateInventoryAsync(int sellerId, int productId, UpdateInventoryRequest req)
    {
        using var db = Conn();

        // Bulk-update every live variant for this product (seller-scoped) so the
        // PATCH applies to all colour/size combos uniformly. Null fields are left untouched.
        const string sql = @"
            UPDATE pv
            SET    pv.[StockQuantity]     = COALESCE(@StockQuantity,     pv.[StockQuantity]),
                   pv.[LowStockThreshold] = COALESCE(@LowStockThreshold, pv.[LowStockThreshold]),
                   pv.[UpdatedAt]         = GETUTCDATE(),
                   pv.[UpdatedBy]         = @UpdatedBy
            FROM   [dbo].[ProductVariants] pv
            INNER JOIN [dbo].[Products] p
                   ON p.[ProductId] = pv.[ProductId]
            WHERE  pv.[ProductId] = @ProductId
              AND  pv.[IsDeleted] = 0
              AND  p.[SellerId]   = @SellerId
              AND  p.[IsDeleted]  = 0;";

        await db.ExecuteAsync(sql,
            new
            {
                ProductId         = productId,
                SellerId          = sellerId,
                StockQuantity     = req.StockQuantity,
                LowStockThreshold = req.LowStockThreshold,
                UpdatedBy         = sellerId
            },
            commandType: System.Data.CommandType.Text);
    }

    public async Task<List<SellerInventoryDto>> GetInventoryAsync(int sellerId)
    {
        using var db = Conn();

        var result = await db.QueryAsync<SellerInventoryDto>(
            @"SELECT p.ProductId, p.ProductName, pv.VariantId, pv.SizeName, pv.ColorName,
                     pv.StockQuantity, pv.LowStockAlert AS LowStockThreshold
              FROM Products p
              LEFT JOIN ProductVariants pv ON pv.ProductId = p.ProductId AND pv.IsDeleted = 0
              WHERE p.SellerId = @SellerId AND p.IsDeleted = 0",
            new { SellerId = sellerId },
            commandType: System.Data.CommandType.Text);

        return result.ToList();
    }

    public async Task<List<SellerInventoryDto>> GetLowStockItemsAsync(int sellerId)
    {
        using var db = Conn();

        var result = await db.QueryAsync<SellerInventoryDto>(
            @"SELECT p.ProductId, p.ProductName, pv.VariantId, pv.SizeName, pv.ColorName,
                     pv.StockQuantity, pv.LowStockAlert AS LowStockThreshold
              FROM Products p
              JOIN ProductVariants pv ON pv.ProductId = p.ProductId AND pv.IsDeleted = 0
              WHERE p.SellerId = @SellerId AND p.IsDeleted = 0
                AND pv.StockQuantity <= pv.LowStockAlert",
            new { SellerId = sellerId },
            commandType: System.Data.CommandType.Text);

        return result.ToList();
    }

    private static string Slugify(string input) =>
        System.Text.RegularExpressions.Regex
            .Replace(input.ToLowerInvariant().Trim(), @"[^a-z0-9]+", "-")
            .Trim('-');
}
