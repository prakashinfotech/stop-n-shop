namespace ShopNShop.Api.DTOs;

public record CouponValidateRequest(string CouponCode, decimal CartTotal);

public class CouponValidateResult
{
    public bool     IsValid        { get; set; }
    public decimal  DiscountAmount { get; set; }
    public string   Message        { get; set; } = string.Empty;
    public string?  CouponCode     { get; set; }
    public string?  DiscountType   { get; set; }
}

public class AdminCouponDto
{
    public int      CouponId           { get; set; }
    public string   CouponCode         { get; set; } = string.Empty;
    public bool     IsActive           { get; set; }
    public int      OfferId            { get; set; }
    public string   OfferName          { get; set; } = string.Empty;
    public byte     OfferType          { get; set; }    // 1=Flat, 2=Percentage
    public decimal  DiscountValue      { get; set; }
    public decimal  MinOrderValue      { get; set; }
    public decimal? MaxDiscountCap     { get; set; }
    public DateTime StartDate          { get; set; }
    public DateTime EndDate            { get; set; }
    public byte     ApplicableOn       { get; set; }    // 1=Product, 2=Brand, 3=Category, 4=Cart
    public int?     EntityId           { get; set; }
    public string?  BrandName          { get; set; }
    public byte     UsageLimitPerUser  { get; set; }
    public int      CurrentUsageCount  { get; set; }
    public DateTime CreatedAt          { get; set; }
}

public class CreateCouponRequest
{
    public string   CouponCode        { get; set; } = string.Empty;
    public string   OfferName         { get; set; } = string.Empty;
    public byte     OfferType         { get; set; } = 2;
    public decimal  DiscountValue     { get; set; }
    public decimal  MinOrderValue     { get; set; } = 0;
    public decimal? MaxDiscountCap    { get; set; }
    public DateTime StartDate         { get; set; }
    public DateTime EndDate           { get; set; }
    public byte     ApplicableOn      { get; set; } = 4;
    public int?     EntityId          { get; set; }
    public byte     UsageLimitPerUser { get; set; } = 1;
}

public record ToggleCouponRequest(bool IsActive);

public class AvailableCouponDto
{
    public int      CouponId           { get; set; }
    public string   CouponCode         { get; set; } = string.Empty;
    public string   OfferName          { get; set; } = string.Empty;
    public byte     OfferType          { get; set; }
    public decimal  DiscountValue      { get; set; }
    public decimal  MinOrderValue      { get; set; }
    public decimal? MaxDiscountCap     { get; set; }
    public byte     ApplicableOn       { get; set; }
    public int?     EntityId           { get; set; }
    public string?  BrandName          { get; set; }
    public DateTime StartDate          { get; set; }
    public DateTime EndDate            { get; set; }
    public byte     UsageLimitPerUser  { get; set; }
    public int      UsedByUser         { get; set; }
    public bool     IsExhausted        => UsageLimitPerUser > 0 && UsedByUser >= UsageLimitPerUser;
}
