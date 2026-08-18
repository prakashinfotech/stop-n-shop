namespace ShopNShop.Api.DTOs;

/// <summary>
/// Print-ready data bundle for a confirmed order item — shipping sticker (A6)
/// and order receipt (A4) are both rendered client-side from this payload.
/// </summary>
public class SellerLabelDataDto
{
    public int      OrderItemId       { get; set; }
    public byte     LineStatus        { get; set; }
    public int      OrderId           { get; set; }
    public string   OrderNumber       { get; set; } = string.Empty;
    public DateTime OrderDate         { get; set; }
    public byte     PaymentMode       { get; set; }   // 1 COD | 2 Online | 3 Wallet
    public byte     PaymentStatus     { get; set; }

    // Line + variant
    public string   ProductName       { get; set; } = string.Empty;
    public string?  VariantSnapshot   { get; set; }
    public int      Quantity          { get; set; }
    public decimal  UnitPrice         { get; set; }
    public decimal  TaxAmount         { get; set; }
    public decimal  TotalPrice        { get; set; }
    public string?  VariantSku        { get; set; }
    public string?  Color             { get; set; }
    public string?  Size              { get; set; }
    public decimal? VariantWeightGm   { get; set; }

    // Render payloads
    public string   BarcodeValue      { get; set; } = string.Empty;
    public string   QrPayload         { get; set; } = string.Empty;

    // Buyer (TO panel) — phone masked at the SP boundary
    public string?  BuyerName         { get; set; }
    public string?  BuyerPhoneMasked  { get; set; }
    public string?  AddressLine1      { get; set; }
    public string?  AddressLine2      { get; set; }
    public string?  BuyerCity         { get; set; }
    public string?  BuyerState        { get; set; }
    public string?  BuyerPincode      { get; set; }
    public string?  BuyerCountry      { get; set; }

    // Seller (FROM panel)
    public string?  SellerBusinessName  { get; set; }
    public string?  SellerGstNumber     { get; set; }
    public string?  SellerSupportPhone  { get; set; }
    public string?  SellerSupportEmail  { get; set; }
    public string?  SellerLogoUrl       { get; set; }
    public string?  SellerAddressLine1  { get; set; }
    public string?  SellerAddressLine2  { get; set; }
    public string?  SellerCity          { get; set; }
    public string?  SellerState         { get; set; }
    public string?  SellerPincode       { get; set; }
}
