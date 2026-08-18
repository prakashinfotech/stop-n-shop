using System.Text.Json.Serialization;

namespace ShopNShop.Api.DTOs;

public class ProductListItemDto
{
    public int      Id           { get; set; }
    public string   Name         { get; set; } = string.Empty;
    [JsonPropertyName("brand")]
    public string?  BrandName    { get; set; }
    public decimal  SellingPrice { get; set; }
    [JsonPropertyName("mrp")]
    public decimal  MRP          { get; set; }
    [JsonPropertyName("discountPercent")]
    public decimal  DiscountPct  { get; set; }
    public string?  PrimaryImage  { get; set; }
    public int      OfferCount    { get; set; }
    public int      CategoryId    { get; set; }
    public int      SubCategoryId { get; set; }
    [JsonIgnore]
    public string?  Gender        { get; set; }
    [JsonIgnore]
    public int      SellerId      { get; set; }
    public ProductSellerDto? Seller { get; set; }
}

public class ProductDetailDto
{
    public int      Id              { get; set; }
    public string   Name            { get; set; } = string.Empty;
    public string?  Description     { get; set; }
    [JsonPropertyName("mrp")]
    public decimal  MRP             { get; set; }
    public decimal  SellingPrice    { get; set; }
    [JsonPropertyName("discountPercent")]
    public decimal  DiscountPct     { get; set; }
    [JsonPropertyName("brand")]
    public string?  BrandName       { get; set; }
    public int      CategoryId      { get; set; }
    public int      SubCategoryId   { get; set; }
    [JsonIgnore] public string?  Gender          { get; set; }
    [JsonIgnore] public int      StockQuantity   { get; set; }
    [JsonIgnore] public string   OrderNumber     { get; set; } = string.Empty;
    [JsonIgnore] public string?  BrandSlug       { get; set; }
    [JsonIgnore] public string?  ProductTypeName { get; set; }
    public string?  SubCategoryName { get; set; }
    public string?  CategoryName    { get; set; }
    [JsonIgnore] public int      SellerId        { get; set; }
    public ProductSellerDetailDto? Seller        { get; set; }
    public List<ProductImageDto>  Images { get; set; } = [];
    public List<ProductSizeDto>   Sizes  { get; set; } = [];
    public List<ProductColorDto>  Colors { get; set; } = [];
    public List<ProductOfferDto>  Offers { get; set; } = [];

    // ── Extended product details (additive; nullable; service applies defaults on read) ──
    public string? Material         { get; set; }
    public string? CareInstructions { get; set; }
    public string? FitType          { get; set; }
    public string? CountryOfOrigin  { get; set; }
    public string? WarrantyInfo     { get; set; }
    public string? DeliveryInfo     { get; set; }
    public int     ReturnPolicyDays { get; set; }
    public List<ProductSpecDto> Specifications { get; set; } = [];
}

public class ProductSpecDto
{
    public string Key   { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
}

public class MasterCouponDto
{
    public string   Code          { get; set; } = string.Empty;
    public string   Name          { get; set; } = string.Empty;
    /// <summary>1=Flat, 2=Percentage, 3=BOGO.</summary>
    public int      OfferType     { get; set; }
    public decimal  DiscountValue { get; set; }
    public decimal  MinOrderValue { get; set; }
    public decimal? MaxDiscount   { get; set; }
    public DateTime EndsAt        { get; set; }
}

public class BankOfferDto
{
    public int      Id          { get; set; }
    public string   Title       { get; set; } = string.Empty;
    public string?  Description { get; set; }
    public decimal? MinSpend    { get; set; }
    public decimal? MaxDiscount { get; set; }
    public string?  TermsUrl    { get; set; }
}

public class OffersMasterDto
{
    public List<MasterCouponDto> Coupons    { get; set; } = [];
    public List<BankOfferDto>    BankOffers { get; set; } = [];
}

public class ProductImageDto
{
    [JsonPropertyName("id")]
    public int    SortOrder { get; set; }
    [JsonPropertyName("url")]
    public string ImageUrl  { get; set; } = string.Empty;
    [JsonIgnore]
    public bool   IsPrimary { get; set; }
}

public class ProductSizeDto
{
    [JsonPropertyName("label")]
    public string SizeLabel     { get; set; } = string.Empty;
    [JsonIgnore]
    public int    StockQuantity { get; set; }
    public bool   InStock       => StockQuantity > 0;
}

public class ProductColorDto
{
    [JsonPropertyName("name")]
    public string  ColorName { get; set; } = string.Empty;
    [JsonPropertyName("hex")]
    public string? ColorHex  { get; set; }
    public bool    InStock   { get; set; } = true;
}

public class ProductOfferDto
{
    [JsonIgnore] public int      Id            { get; set; }
    [JsonIgnore] public string   Title         { get; set; } = string.Empty;
    [JsonIgnore] public decimal? MinOrderValue { get; set; }
    public string?  Description  { get; set; }
    public string?  Code         { get; set; }
    public string   DiscountType { get; set; } = string.Empty;
    [JsonPropertyName("value")]
    public decimal  DiscountValue { get; set; }
}

public class ProductQueryParams
{
    public int?     MenuId        { get; set; }
    public int?     CategoryId    { get; set; }
    public int?     SubCategoryId { get; set; }
    public string?  BrandIds      { get; set; }
    public string?  Gender        { get; set; }
    public string?  Sizes         { get; set; }
    public string?  Colors        { get; set; }
    public decimal? MinPrice      { get; set; }
    public decimal? MaxPrice      { get; set; }
    public decimal? MinDiscount   { get; set; }
    public string   SortBy        { get; set; } = "POPULAR";
    public int      PageNo        { get; set; } = 1;
    public int      PageSize      { get; set; } = 20;
    public string?  Search        { get; set; }
    public string?  DatePosted    { get; set; }
}

public class ProductSellerDto
{
    public int     Id       { get; set; }
    public string  Name     { get; set; } = string.Empty;
    public string? Logo     { get; set; }
}

public class ProductSellerDetailDto
{
    public int      Id          { get; set; }
    public string   Name        { get; set; } = string.Empty;
    public string?  Description { get; set; }
    public string?  Logo        { get; set; }
    public string?  Banner      { get; set; }
    public string?  Email       { get; set; }
    public string?  Phone       { get; set; }
}

// ---- Review DTOs ----

public class ReviewDto
{
    public int      ReviewId       { get; set; }
    public string   ReviewerName   { get; set; } = "Anonymous";
    public int      Rating         { get; set; }
    public string?  Title          { get; set; }
    public string?  Body           { get; set; }
    public DateTime CreatedAt      { get; set; }
    public int      HelpfulCount   { get; set; }
}

public class AddReviewRequest
{
    public int    Rating  { get; set; }
    public string Comment { get; set; } = string.Empty;
}

public class ProductReviewsDto
{
    public decimal        AverageRating { get; set; }
    public int            TotalCount    { get; set; }
    public List<ReviewDto> Items        { get; set; } = [];
}
