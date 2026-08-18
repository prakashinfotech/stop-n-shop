using System.Text.Json.Serialization;

namespace ShopNShop.Api.DTOs;

public class MegaMenuCategoryDto
{
    [JsonPropertyName("id")]
    public int TopMenuId { get; set; }
    [JsonPropertyName("name")]
    public string TopMenuName { get; set; } = string.Empty;
    [JsonPropertyName("slug")]
    public string TopMenuSlug { get; set; } = string.Empty;
    public List<MegaMenuSubCategoryDto> SubCategories { get; set; } = [];
}

public class MegaMenuSubCategoryDto
{
    [JsonPropertyName("id")]
    public int SubMenuId { get; set; }
    [JsonPropertyName("name")]
    public string SubMenuName { get; set; } = string.Empty;
    [JsonIgnore]
    public string SubMenuSlug { get; set; } = string.Empty;
    [JsonPropertyName("iconUrl")]
    public string? SubMenuIconUrl { get; set; }
    public List<MegaMenuProductTypeDto> ProductTypes { get; set; } = [];
}

public class MegaMenuProductTypeDto
{
    [JsonPropertyName("id")]
    public int SubSubMenuId { get; set; }
    [JsonPropertyName("name")]
    public string SubSubMenuName { get; set; } = string.Empty;
    [JsonIgnore]
    public string SubSubMenuSlug { get; set; } = string.Empty;
    [JsonPropertyName("iconUrl")]
    public string? SubSubMenuIconUrl { get; set; }
}

public class BannerDto
{
    public int     Id              { get; set; }
    public int     Section         { get; set; }  // BannerType 1–7
    public string  ImageUrl        { get; set; } = string.Empty;
    public string? MobileImageUrl  { get; set; }
    public string? Title           { get; set; }
    public string? Subtitle        { get; set; }
    public string? LinkUrl         { get; set; }
    public int     SortOrder       { get; set; }
    /// <summary>Vertical gap (px) the CMS author wants below this banner in the home stack.</summary>
    public int     GapBelowPx      { get; set; } = 32;
    /// <summary>Optional surface colour rendered behind this banner.</summary>
    public string? BackgroundColor { get; set; }
}

public class StoreDto
{
    public int      Id      { get; set; }
    public string   Name    { get; set; } = string.Empty;
    public string   Address { get; set; } = string.Empty;
    public string   City    { get; set; } = string.Empty;
    public string   State   { get; set; } = string.Empty;
    public string   Pincode { get; set; } = string.Empty;
    public decimal? Lat     { get; set; }
    public decimal? Lng     { get; set; }
    public string?  Phone   { get; set; }
}

public class PincodeDeliveryDto
{
    public string  Pincode       { get; set; } = string.Empty;
    public string  City          { get; set; } = string.Empty;
    public string  State         { get; set; } = string.Empty;
    public bool    IsDeliverable { get; set; }
    public int     EstimatedDays { get; set; }
}

public class CategoryDropdownDto
{
    public int Id { get; set; }
    public int MenuId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string MenuName { get; set; } = string.Empty;
}

public class SubCategoryDropdownDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class FeaturedSubCategoryDto
{
    public int     SubCategoryId   { get; set; }
    public string  SubCategoryName { get; set; } = string.Empty;
    public string  SlugUrl         { get; set; } = string.Empty;
    public string? IconUrl         { get; set; }
    public int     SortOrder       { get; set; }
    public int     CategoryId      { get; set; }
    public string  CategoryName    { get; set; } = string.Empty;
    public string  CategorySlug    { get; set; } = string.Empty;
    public int     MenuId          { get; set; }
    public string  MenuName        { get; set; } = string.Empty;
    public string  MenuSlug        { get; set; } = string.Empty;
}

public class SubCategoryFormSchemaDto
{
    public int     SubCategoryId      { get; set; }
    public string  SubCategoryName    { get; set; } = string.Empty;
    public string[] ImageAngles       { get; set; } = System.Array.Empty<string>();
    public string  SizeScale          { get; set; } = "none";
    public bool    RequiresGender     { get; set; }
    public bool    RequiresDimensions { get; set; }
}

public class BrandDropdownDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
}

public class MegaMenuRawDto
{
    public int TopMenuId { get; set; }
    public string TopMenuName { get; set; } = string.Empty;
    public string TopMenuSlug { get; set; } = string.Empty;
    public int SubMenuId { get; set; }
    public string SubMenuName { get; set; } = string.Empty;
    public string SubMenuSlug { get; set; } = string.Empty;
    public string? SubMenuIconUrl { get; set; }
    public int SubSubMenuId { get; set; }
    public string SubSubMenuName { get; set; } = string.Empty;
    public string SubSubMenuSlug { get; set; } = string.Empty;
    public string? SubSubMenuIconUrl { get; set; }
}
