using System.Text.Json.Serialization;

namespace ShopNShop.Api.DTOs;

// --- WISHLIST ---
public class WishlistItemDto
{
    public int      Id           { get; set; }
    public int      ProductId    { get; set; }
    [JsonPropertyName("productName")]
    public string   Name         { get; set; } = string.Empty;
    [JsonPropertyName("mrp")]
    public decimal  MRP          { get; set; }
    public decimal  SellingPrice { get; set; }
    [JsonPropertyName("discountPercent")]
    public decimal  DiscountPct  { get; set; }
    [JsonPropertyName("brand")]
    public string?  BrandName    { get; set; }
    public string?  PrimaryImage { get; set; }
    public int      OfferCount   { get; set; }
    public DateTime CreatedAt    { get; set; }
}

// --- CART ---
public class CartItemDto
{
    [JsonPropertyName("id")]
    public int      CartId       { get; set; }
    public int      ProductId    { get; set; }
    public string   ProductName  { get; set; } = string.Empty;
    [JsonPropertyName("brand")]
    public string?  BrandName    { get; set; }
    [JsonPropertyName("imageUrl")]
    public string?  PrimaryImage { get; set; }
    public string?  SizeLabel    { get; set; }
    public string?  ColorName    { get; set; }
    public int      Quantity     { get; set; }
    public decimal  SellingPrice { get; set; }
    [JsonPropertyName("mrp")]
    public decimal  MRP          { get; set; }
    [JsonPropertyName("discountPercent")]
    public decimal  DiscountPct  { get; set; }
    [JsonPropertyName("itemMrp")]
    public decimal  ItemMRP      { get; set; }
    public decimal  ItemTotal    { get; set; }
}

public class CartSummaryDto
{
    public decimal TotalMRP       { get; set; }
    public decimal TotalDiscount  { get; set; }
    public decimal DeliveryCharge { get; set; }
    public decimal FinalAmount    { get; set; }
    [JsonIgnore] public decimal SubTotal  { get; set; }
    [JsonIgnore] public int     ItemCount { get; set; }
}

public class CartDto
{
    public List<CartItemDto> Items   { get; set; } = [];
    public CartSummaryDto    Summary { get; set; } = null!;
}

public class AddToCartRequest
{
    public int     ProductId { get; set; }
    public string? SizeLabel { get; set; }
    public string? ColorName { get; set; }
    public int     Quantity  { get; set; } = 1;
}

public class UpdateCartRequest
{
    public int Quantity { get; set; }
}

// --- ORDERS ---
public class PlaceOrderRequest
{
    public int     AddressId     { get; set; }
    public string  PaymentMethod { get; set; } = string.Empty;
    public string? CouponCode    { get; set; }
}

public class OrderListItemDto
{
    public int      Id            { get; set; }
    public string   OrderNumber   { get; set; } = string.Empty;
    public string   Status        { get; set; } = string.Empty;
    public decimal  FinalAmount   { get; set; }
    public string   PaymentMethod { get; set; } = string.Empty;
    public DateTime CreatedAt     { get; set; }
    [JsonPropertyName("primaryImage")]
    public string?  ThumbnailUrl  { get; set; }
    public int      ItemCount     { get; set; }
}

public class OrderDetailDto
{
    public int      Id            { get; set; }
    public string   OrderNumber   { get; set; } = string.Empty;
    public string   Status        { get; set; } = string.Empty;
    public string   PaymentMethod { get; set; } = string.Empty;
    public string   PaymentStatus { get; set; } = string.Empty;
    public DateTime CreatedAt     { get; set; }

    // Flat address fields populated by Dapper — hidden from JSON output
    [JsonIgnore] public decimal  TotalMRP       { get; set; }
    [JsonIgnore] public decimal  TotalDiscount  { get; set; }
    [JsonIgnore] public decimal  CouponDiscount { get; set; }
    [JsonIgnore] public string?  CouponCode     { get; set; }
    [JsonIgnore] public decimal  DeliveryCharge { get; set; }
    [JsonIgnore] public decimal  FinalAmount    { get; set; }
    [JsonIgnore] public string?  ShipToName     { get; set; }
    [JsonIgnore] public string?  ShipToMobile   { get; set; }
    [JsonIgnore] public string?  AddressLine1   { get; set; }
    [JsonIgnore] public string?  AddressLine2   { get; set; }
    [JsonIgnore] public string?  City           { get; set; }
    [JsonIgnore] public string?  State          { get; set; }
    [JsonIgnore] public string?  Pincode        { get; set; }

    // Nested shapes for JSON — assembled from Dapper-populated flat fields
    public OrderShippingAddressDto Address => new()
    {
        Name    = ShipToName ?? string.Empty,
        Mobile  = ShipToMobile ?? string.Empty,
        Line1   = AddressLine1 ?? string.Empty,
        Line2   = AddressLine2,
        City    = City ?? string.Empty,
        State   = State ?? string.Empty,
        Pincode = Pincode ?? string.Empty
    };

    public OrderSummaryDto Summary => new()
    {
        TotalMRP       = TotalMRP,
        TotalDiscount  = TotalDiscount,
        CouponDiscount = CouponDiscount,
        CouponCode     = CouponCode,
        DeliveryCharge = DeliveryCharge,
        FinalAmount    = FinalAmount
    };

    public List<OrderItemDto>     Items    { get; set; } = [];
    public List<OrderTrackingDto> Tracking { get; set; } = [];
}

public class OrderShippingAddressDto
{
    public string  Name    { get; set; } = string.Empty;
    public string  Mobile  { get; set; } = string.Empty;
    public string  Line1   { get; set; } = string.Empty;
    public string? Line2   { get; set; }
    public string  City    { get; set; } = string.Empty;
    public string  State   { get; set; } = string.Empty;
    public string  Pincode { get; set; } = string.Empty;
}

public class OrderSummaryDto
{
    public decimal TotalMRP       { get; set; }
    public decimal TotalDiscount  { get; set; }
    public decimal CouponDiscount { get; set; }
    public string? CouponCode     { get; set; }
    public decimal DeliveryCharge { get; set; }
    public decimal FinalAmount    { get; set; }
}

public class OrderItemDto
{
    public int      Id          { get; set; }
    public int      ProductId   { get; set; }
    public string   ProductName { get; set; } = string.Empty;
    [JsonPropertyName("brand")]
    public string?  BrandName   { get; set; }
    public string?  ImageUrl    { get; set; }
    public string?  SizeLabel   { get; set; }
    public string?  ColorName   { get; set; }
    [JsonIgnore]
    public decimal  MRP         { get; set; }
    public decimal  SellingPrice { get; set; }
    public int      Quantity    { get; set; }
    /// <summary>Per-line fulfilment state — 1=Placed, 2=Confirmed, …, 8=Rejected.</summary>
    public byte     LineStatus  { get; set; } = 1;
    public DateTime? ConfirmedAt    { get; set; }
    public DateTime? RejectedAt     { get; set; }
    public string?   RejectionReason { get; set; }
}

public class OrderTrackingDto
{
    public string   Status      { get; set; } = string.Empty;
    public string?  Description { get; set; }
    public DateTime CreatedAt   { get; set; }
}

// --- ADDRESSES ---
public class AddressDto
{
    public int     Id           { get; set; }
    public string  Name         { get; set; } = string.Empty;
    public string  Mobile       { get; set; } = string.Empty;
    [JsonPropertyName("line1")]
    public string  AddressLine1 { get; set; } = string.Empty;
    [JsonPropertyName("line2")]
    public string? AddressLine2 { get; set; }
    public string  City         { get; set; } = string.Empty;
    public string  State        { get; set; } = string.Empty;
    public string  Pincode      { get; set; } = string.Empty;
    public bool    IsDefault    { get; set; }
}

public class AddAddressRequest
{
    public string  Name         { get; set; } = string.Empty;
    public string  Mobile       { get; set; } = string.Empty;
    [JsonPropertyName("line1")]
    public string  AddressLine1 { get; set; } = string.Empty;
    [JsonPropertyName("line2")]
    public string? AddressLine2 { get; set; }
    public string  City         { get; set; } = string.Empty;
    public string  State        { get; set; } = string.Empty;
    public string  Pincode      { get; set; } = string.Empty;
    public bool    IsDefault    { get; set; }
}

// --- ORDER CANCELLATION & STATUS ---
public class CancelOrderRequest
{
    public string Reason { get; set; } = string.Empty;
}

public class UpdateOrderStatusByNumRequest
{
    public int NewStatus { get; set; }
}
