namespace ShopNShop.Api.DTOs;

public class VariantAttributeDto
{
    public int     AttributeId  { get; set; }
    public string  AttributeKey { get; set; } = string.Empty;
    public string  DisplayName  { get; set; } = string.Empty;
    public string  InputType    { get; set; } = "select";
    public int     SortOrder    { get; set; }
    public bool    IsActive     { get; set; }
}

public class SubCategoryVariantOptionDto
{
    public int     OptionId        { get; set; }
    public int     SubCategoryId   { get; set; }
    public int     AttributeId     { get; set; }
    public string  AttributeKey    { get; set; } = string.Empty;
    public string  AttributeName   { get; set; } = string.Empty;
    public string  InputType       { get; set; } = "select";
    public string  OptionValue     { get; set; } = string.Empty;
    public string? OptionMetadata  { get; set; }
    public int     SortOrder       { get; set; }
    public bool    IsActive        { get; set; }
}

public class SellerVariantOptionDto
{
    public int     OptionId             { get; set; }
    public int     SubCategoryId        { get; set; }
    public int     AttributeId          { get; set; }
    public string  AttributeKey         { get; set; } = string.Empty;
    public string  AttributeName        { get; set; } = string.Empty;
    public string  InputType            { get; set; } = "select";
    public string  OptionValue          { get; set; } = string.Empty;
    public string? OptionMetadata       { get; set; }
    public int     SortOrder            { get; set; }
    public bool    IsDisabledForProduct { get; set; }
}

public record VariantOptionUpsertRequest(
    int?    OptionId,
    int     SubCategoryId,
    int     AttributeId,
    string  OptionValue,
    string? OptionMetadata,
    int     SortOrder);

public record VariantOptionBulkItem(string OptionValue, string? OptionMetadata, int SortOrder);
public record VariantOptionBulkSetRequest(int SubCategoryId, int AttributeId, List<VariantOptionBulkItem> Options);

public record SetDisabledOptionsRequest(List<int> OptionIds);
