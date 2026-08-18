using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IProductRepository
{
    Task<(List<ProductListItemDto> Items, int TotalCount)> GetProductsAsync(ProductQueryParams q);
    Task<ProductDetailDto?> GetProductDetailAsync(int id);
    Task<List<ProductListItemDto>> GetSimilarProductsAsync(int id, int pageSize = 10);
    Task<List<ProductListItemDto>> GetRecommendedProductsAsync(string productIds, int pageSize = 10);
    Task<List<ProductListItemDto>> GetTrendingProductsAsync(int windowDays = 7, int limit = 12);
    Task<OffersMasterDto> GetOffersMasterAsync();
}

public class ProductRepository(IConfiguration config) : IProductRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<(List<ProductListItemDto> Items, int TotalCount)> GetProductsAsync(ProductQueryParams q)
    {
        using var db = Conn();

        var rows = (await db.QueryAsync<ProductSearchRow>(
            "usp_Catalog_Product_Search",
            new
            {
                SearchTerm    = q.Search ?? string.Empty,
                CategoryId    = q.CategoryId,
                SubCategoryId = q.SubCategoryId,
                MenuId        = q.MenuId,
                BrandId       = (int?)null,
                BrandIds      = q.BrandIds,
                Sizes         = q.Sizes,
                Colors        = q.Colors,
                GenderTypeId  = (byte?)null,
                MinPrice      = q.MinPrice,
                MaxPrice      = q.MaxPrice,
                SortBy        = MapSortBy(q.SortBy),
                PageNumber    = q.PageNo,
                PageSize      = q.PageSize,
                CallerUserId  = (int?)null,
                DatePosted    = q.DatePosted
            },
            commandType: System.Data.CommandType.StoredProcedure)).AsList();

        int totalCount = rows.Count > 0 ? rows[0].TotalCount : 0;

        var items = rows.Select(r => new ProductListItemDto
        {
            Id            = r.Id,
            Name          = r.Name,
            MRP           = r.MRP,
            SellingPrice  = r.SellingPrice,
            DiscountPct   = r.DiscountPct,
            BrandName     = r.BrandName,
            PrimaryImage  = r.PrimaryImage,
            CategoryId    = r.CategoryId,
            SubCategoryId = r.SubCategoryId,
            SellerId      = r.SellerId
        }).ToList();

        return (items, totalCount);
    }

    private sealed class ProductSearchRow
    {
        public int     Id            { get; set; }
        public string  Name          { get; set; } = string.Empty;
        public string? SlugUrl       { get; set; }
        public int     CategoryId    { get; set; }
        public int     SubCategoryId { get; set; }
        public int     SellerId      { get; set; }
        public decimal MRP           { get; set; }
        public decimal SellingPrice  { get; set; }
        public decimal DiscountPct   { get; set; }
        public string? BrandName     { get; set; }
        public string? PrimaryImage  { get; set; }
        public int     MinStock      { get; set; }
        public int     TotalCount    { get; set; }
    }

    public async Task<ProductDetailDto?> GetProductDetailAsync(int id)
    {
        using var db = Conn();

        using var multi = await db.QueryMultipleAsync(
            "usp_Catalog_Product_GetById",
            new { ProductId = id },
            commandType: System.Data.CommandType.StoredProcedure);

        var raw = await multi.ReadSingleOrDefaultAsync<dynamic>();
        if (raw is null) return null;

        decimal mrp  = raw.MRP;
        decimal sell = raw.SellingPrice;

        var dto = new ProductDetailDto
        {
            Id               = raw.ProductId,
            Name             = raw.ProductName,
            Description      = (string?)raw.LongDescription ?? (string?)raw.ShortDescription,
            MRP              = mrp,
            SellingPrice     = sell,
            DiscountPct      = mrp > 0 ? Math.Round((mrp - sell) * 100m / mrp, 1) : 0,
            BrandName        = raw.BrandName,
            CategoryId       = raw.CategoryId,
            SubCategoryId    = raw.SubCategoryId ?? 0,
            SellerId         = raw.SellerId,
            CategoryName     = TryGet<string>(raw, "CategoryName"),
            SubCategoryName  = TryGet<string>(raw, "SubCategoryName"),
            Material         = TryGet<string>(raw, "Material"),
            CareInstructions = TryGet<string>(raw, "CareInstructions"),
            FitType          = TryGet<string>(raw, "FitType"),
            CountryOfOrigin  = TryGet<string>(raw, "CountryOfOrigin"),
            WarrantyInfo     = TryGet<string>(raw, "WarrantyInfo"),
            DeliveryInfo     = TryGet<string>(raw, "DeliveryInfo"),
            ReturnPolicyDays = (int)(byte)(raw.ReturnWindowDays ?? (byte)0)
        };

        // Result set #2: variants
        if (!multi.IsConsumed)
        {
            var variants = (await multi.ReadAsync<dynamic>()).ToList();

            dto.Sizes = variants
                .Where(v => !string.IsNullOrWhiteSpace((string?)v.Size))
                .GroupBy(v => (string)v.Size)
                .Select(g => new ProductSizeDto
                {
                    SizeLabel     = g.Key,
                    StockQuantity = g.Sum(v => (int)(v.StockQuantity ?? 0))
                })
                .ToList();

            dto.Colors = variants
                .Where(v => !string.IsNullOrWhiteSpace((string?)v.Color))
                .GroupBy(v => (string)v.Color)
                .Select(g => new ProductColorDto
                {
                    ColorName = g.Key,
                    ColorHex  = (string?)g.First().ColorHexCode,
                    InStock   = g.Sum(v => (int)(v.StockQuantity ?? 0)) > 0
                })
                .ToList();
        }

        // Result set #3: images
        if (!multi.IsConsumed)
        {
            var images = (await multi.ReadAsync<dynamic>()).ToList();
            if (images.Count > 0)
            {
                dto.Images = images
                    .Where(i => i.ImageUrl != null)
                    .Select(i => new ProductImageDto
                    {
                        ImageUrl  = (string)i.ImageUrl,
                        IsPrimary = (bool)(i.IsPrimary ?? false),
                        SortOrder = (int)(i.SortOrder ?? 0)
                    })
                    .ToList();
            }
        }

        // Result set #4: specifications (key/value rows)
        if (!multi.IsConsumed)
        {
            var specs = (await multi.ReadAsync<dynamic>()).ToList();
            dto.Specifications = specs
                .Select(s => new ProductSpecDto
                {
                    Key   = (string)s.SpecKey,
                    Value = (string)s.SpecValue
                })
                .ToList();
        }

        return dto;
    }

    private static T? TryGet<T>(dynamic row, string key) where T : class
    {
        var dict = (IDictionary<string, object>)row;
        if (!dict.TryGetValue(key, out var value) || value is null) return null;
        return value as T;
    }

    public async Task<List<ProductListItemDto>> GetSimilarProductsAsync(int id, int pageSize = 10)
    {
        using var db = Conn();

        var categoryId = await db.QuerySingleOrDefaultAsync<int?>(
            "SELECT CategoryId FROM Products WHERE ProductId = @ProductId AND IsDeleted = 0",
            new { ProductId = id },
            commandType: System.Data.CommandType.Text);

        if (categoryId is null) return [];

        var rows = (await db.QueryAsync<ProductSearchRow>(
            "usp_Catalog_Product_Search",
            new
            {
                SearchTerm   = string.Empty,
                CategoryId   = categoryId,
                BrandId      = (int?)null,
                GenderTypeId = (byte?)null,
                MinPrice     = (decimal?)null,
                MaxPrice     = (decimal?)null,
                SortBy       = "Newest",
                PageNumber   = 1,
                PageSize     = pageSize,
                CallerUserId = (int?)null
            },
            commandType: System.Data.CommandType.StoredProcedure)).AsList();

        return rows.Where(r => r.Id != id).Select(r => new ProductListItemDto
        {
            Id           = r.Id,
            Name         = r.Name,
            MRP          = r.MRP,
            SellingPrice = r.SellingPrice,
            DiscountPct  = r.DiscountPct,
            BrandName    = r.BrandName,
            PrimaryImage = r.PrimaryImage,
            SellerId     = r.SellerId
        }).ToList();
    }

    /// <summary>
    /// Trending = top products by rolling-window view count from ProductViewLogs.
    /// Falls back to featured/newest when there's no view activity (e.g. fresh installs).
    /// </summary>
    public async Task<List<ProductListItemDto>> GetTrendingProductsAsync(int windowDays = 7, int limit = 12)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<ProductListItemDto>(
            "usp_Catalog_Product_GetTrending",
            new { WindowDays = windowDays, Limit = limit },
            commandType: System.Data.CommandType.StoredProcedure);
        return rows.AsList();
    }

    public async Task<List<ProductListItemDto>> GetRecommendedProductsAsync(string productIds, int pageSize = 10)
    {
        using var db = Conn();

        var rows = (await db.QueryAsync<ProductSearchRow>(
            "usp_Catalog_Product_Search",
            new
            {
                SearchTerm   = string.Empty,
                CategoryId   = (int?)null,
                BrandId      = (int?)null,
                GenderTypeId = (byte?)null,
                MinPrice     = (decimal?)null,
                MaxPrice     = (decimal?)null,
                SortBy       = "Newest",
                PageNumber   = 1,
                PageSize     = pageSize,
                CallerUserId = (int?)null
            },
            commandType: System.Data.CommandType.StoredProcedure)).AsList();

        return rows.Select(r => new ProductListItemDto
        {
            Id           = r.Id,
            Name         = r.Name,
            MRP          = r.MRP,
            SellingPrice = r.SellingPrice,
            DiscountPct  = r.DiscountPct,
            BrandName    = r.BrandName,
            PrimaryImage = r.PrimaryImage,
            SellerId     = r.SellerId
        }).ToList();
    }

    public async Task<OffersMasterDto> GetOffersMasterAsync()
    {
        using var db = Conn();
        using var multi = await db.QueryMultipleAsync(
            "usp_Pricing_OffersMaster_Get",
            commandType: System.Data.CommandType.StoredProcedure);

        var coupons = (await multi.ReadAsync<dynamic>())
            .Select(r => new MasterCouponDto
            {
                Code          = (string)r.CouponCode,
                Name          = (string)r.OfferName,
                OfferType     = (int)(byte)r.OfferType,
                DiscountValue = (decimal)r.DiscountValue,
                MinOrderValue = (decimal)r.MinOrderValue,
                MaxDiscount   = (decimal?)r.MaxDiscountCap,
                EndsAt        = (DateTime)r.EndDate,
            })
            .ToList();

        var bankOffers = (await multi.ReadAsync<dynamic>())
            .Select(r => new BankOfferDto
            {
                Id          = (int)r.BankOfferId,
                Title       = (string)r.Title,
                Description = (string?)r.Description,
                MinSpend    = (decimal?)r.MinSpend,
                MaxDiscount = (decimal?)r.MaxDiscount,
                TermsUrl    = (string?)r.TermsUrl,
            })
            .ToList();

        return new OffersMasterDto { Coupons = coupons, BankOffers = bankOffers };
    }

    /// <summary>
    /// `BrandIds` arrives as a CSV ("1,3,7"). The SP only filters one brand today,
    /// so we pass the first; the UI multi-brand picker still narrows the rest client-side.
    /// </summary>
    private static int? TryParseFirstBrand(string? csv) =>
        string.IsNullOrWhiteSpace(csv) ? null
        : int.TryParse(csv.Split(',', StringSplitOptions.RemoveEmptyEntries)[0], out var id) ? id : null;

    private static string MapSortBy(string? sortBy) => sortBy?.ToLower() switch
    {
        "price_asc"  or "pricelow"  => "PriceLow",
        "price_desc" or "pricehigh" => "PriceHigh",
        "newest"                    => "Newest",
        _                           => "Relevance"
    };
}
