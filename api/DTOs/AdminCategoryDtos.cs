namespace ShopNShop.Api.DTOs;

public class AdminCategoryDto
{
    public int      CategoryId        { get; set; }
    public int      MenuId            { get; set; }
    public string?  MenuName          { get; set; }
    public string   CategoryName      { get; set; } = string.Empty;
    public string   SlugUrl           { get; set; } = string.Empty;
    public string?  IconUrl           { get; set; }
    public string?  BannerUrl         { get; set; }
    public int      SortOrder         { get; set; }
    public bool     IsFeatured        { get; set; }
    public bool     ShowInMegaMenu    { get; set; }
    public bool     IsActive          { get; set; }
    public string?  MetaTitle         { get; set; }
    public string?  MetaDescription   { get; set; }
    public int      SubCategoryCount  { get; set; }
    public int      ProductCount      { get; set; }
}

public class AdminSubCategoryDto
{
    public int      SubCategoryId     { get; set; }
    public int      CategoryId        { get; set; }
    public string   SubCategoryName   { get; set; } = string.Empty;
    public string   SlugUrl           { get; set; } = string.Empty;
    public string?  IconUrl           { get; set; }
    public int      SortOrder         { get; set; }
    public bool     IsFeatured        { get; set; }
    public bool     ShowInMegaMenu    { get; set; }
    public bool     IsActive          { get; set; }
    public string?  MetaTitle         { get; set; }
    public string?  MetaDescription   { get; set; }
    public int      ProductCount      { get; set; }
}

public class AdminMegaMenuTreeDto
{
    public List<AdminCategoryDto>    Categories    { get; set; } = new();
    public List<AdminSubCategoryDto> SubCategories { get; set; } = new();
}

public record AdminCategoryUpsertRequest(
    int?    CategoryId,
    int     MenuId,
    string  CategoryName,
    string  SlugUrl,
    string? IconUrl,
    string? BannerUrl,
    int     SortOrder,
    bool    IsFeatured,
    bool    ShowInMegaMenu,
    string? MetaTitle,
    string? MetaDescription);

public record AdminSubCategoryUpsertRequest(
    int?    SubCategoryId,
    int     CategoryId,
    string  SubCategoryName,
    string  SlugUrl,
    string? IconUrl,
    int     SortOrder,
    bool    IsFeatured,
    bool    ShowInMegaMenu,
    string? MetaTitle,
    string? MetaDescription);

public record ToggleVisibilityRequest(bool? IsActive, bool? ShowInMegaMenu);

public record CategoryReorderItem(int CategoryId, int SortOrder);
public record SubCategoryReorderItem(int SubCategoryId, int SortOrder);

public record CategoryReorderRequest(List<CategoryReorderItem> Items);
public record SubCategoryReorderRequest(List<SubCategoryReorderItem> Items);

public record UpdateFormRulesRequest(
    string[] ImageAngles,
    string   SizeScale,
    bool     RequiresGender,
    bool     RequiresDimensions);
