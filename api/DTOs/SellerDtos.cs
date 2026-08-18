using System.Text.Json.Serialization;

namespace ShopNShop.Api.DTOs;

/// <summary>Seller signup request — slim, credentials only.</summary>
public class SellerSignupRequest
{
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string ConfirmPassword { get; set; } = string.Empty;
}

/// <summary>Seller login request.</summary>
public class SellerLoginRequest
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

/// <summary>Seller profile DTO (response).</summary>
public class SellerProfileDto
{
    public int Id { get; set; }
    public string? BusinessName { get; set; }
    public string? OwnerName { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string? GSTNumber { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Pincode { get; set; }
    public string? DisplayName { get; set; }
    public string? StoreDescription { get; set; }
    public string? BannerUrl { get; set; }
    public string? LogoUrl { get; set; }
    public string? SupportEmail { get; set; }
    public string? SupportPhone { get; set; }
    public string? Description { get; set; }
    public bool IsPhoneVerified { get; set; }
    public bool IsEmailVerified { get; set; }
    public bool IsIdVerified { get; set; }
    public bool OnboardingCompleted { get; set; }
    public string? PickupAddressLine1 { get; set; }
    public string? PickupAddressLine2 { get; set; }
    public string? PickupCity { get; set; }
    public string? PickupState { get; set; }
    public string? PickupPincode { get; set; }
    public string? PickupLandmark { get; set; }
    public string? SelectedCategories { get; set; }
    public bool IsActive { get; set; }
    public bool IsApproved { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    [JsonIgnore]
    public string? PasswordHash { get; set; }
}

/// <summary>Seller update profile request.</summary>
public class UpdateSellerProfileRequest
{
    public string? BusinessName { get; set; }
    public string? OwnerName { get; set; }
    public string? PhoneNumber { get; set; }
    public string? GSTNumber { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? Pincode { get; set; }
    public string? BannerUrl { get; set; }
    public string? LogoUrl { get; set; }
    public string? SupportEmail { get; set; }
    public string? SupportPhone { get; set; }
    public string? Description { get; set; }
}

/// <summary>Seller auth response (token + profile).</summary>
public class SellerAuthResponse
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public SellerProfileDto Seller { get; set; } = new();
}

/// <summary>Seller signup response — includes OTPs for initial testing phase.</summary>
public class SellerSignupResponse
{
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public SellerProfileDto Seller { get; set; } = new();
    public string PhoneOtp { get; set; } = string.Empty;  // For initial testing phase only
    public string EmailOtp { get; set; } = string.Empty;  // For initial testing phase only
}

/// <summary>Seller onboarding request.</summary>
public class SellerOnboardingRequest
{
    public string OwnerFullName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string StoreDescription { get; set; } = string.Empty;
    public bool IsPhoneVerified { get; set; } = true;
    public bool IsEmailVerified { get; set; } = true;
    public bool IsIdVerified { get; set; }
    public bool AllCategories { get; set; } = true;
    public List<int> SelectedCategoryIds { get; set; } = [];
    public string PickupAddressLine1 { get; set; } = string.Empty;
    public string? PickupAddressLine2 { get; set; }
    public string PickupCity { get; set; } = string.Empty;
    public string PickupState { get; set; } = string.Empty;
    public string PickupPincode { get; set; } = string.Empty;
    public string? PickupLandmark { get; set; }
}

/// <summary>Create seller product request.</summary>
public class CreateSellerProductRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int CategoryId { get; set; }
    public int SubCategoryId { get; set; }
    public int ProductTypeId { get; set; }
    public int? BrandId { get; set; }
    public decimal MRP { get; set; }
    public decimal SellingPrice { get; set; }
    public decimal? CostPrice { get; set; }
    public string? Gender { get; set; }
    public int StockQuantity { get; set; }
    public int LowStockThreshold { get; set; } = 10;
    public List<string>? ImageUrls { get; set; }
    public List<ProductImagePayload>? Images { get; set; }   // preferred — slot-aware
    public List<string>? Colors { get; set; }
    public List<string>? Sizes  { get; set; }
    public List<string>? Tags   { get; set; }

    /// <summary>Per-cell stock matrix. When provided, overrides the uniform Colors×Sizes expansion.</summary>
    public List<ProductVariantCell>? VariantMatrix { get; set; }

    // ── Extended product details (all optional) ──
    public string? Material         { get; set; }
    public string? CareInstructions { get; set; }
    public string? FitType          { get; set; }
    public string? CountryOfOrigin  { get; set; }
    public string? WarrantyInfo     { get; set; }
    public string? DeliveryInfo     { get; set; }
    public List<ProductSpecDto>? Specifications { get; set; }

    // ── Physical dimensions (rendered when subcategory.requiresDimensions = true) ──
    public decimal? LengthCm  { get; set; }
    public decimal? WidthCm   { get; set; }
    public decimal? HeightCm  { get; set; }
    public decimal? WeightGm  { get; set; }
}

public class ProductImagePayload
{
    public string Url  { get; set; } = string.Empty;
    public string? Slot { get; set; }   // front|back|left|right|top|bottom|detail|single
}

/// <summary>One color×size cell from the seller's variant matrix.</summary>
public class ProductVariantCell
{
    public string? Color           { get; set; }
    public string? Size            { get; set; }
    public int     StockQuantity   { get; set; }
    public decimal AdditionalPrice { get; set; }
    public string? VariantSku      { get; set; }   // optional — server auto-generates when blank
}

/// <summary>Update seller product request.</summary>
public class UpdateSellerProductRequest
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public int? CategoryId { get; set; }
    public int? SubCategoryId { get; set; }
    public int? BrandId { get; set; }
    public decimal? MRP { get; set; }
    public decimal? SellingPrice { get; set; }
    public decimal? CostPrice { get; set; }
    public string? Gender { get; set; }
    public int? StockQuantity { get; set; }
    public int? LowStockThreshold { get; set; }
    public List<string>? ImageUrls { get; set; }
    public List<ProductImagePayload>? Images { get; set; }
    public List<string>? Colors { get; set; }
    public List<string>? Sizes  { get; set; }
    public List<string>? Tags   { get; set; }

    /// <summary>Per-cell stock matrix. When provided, replaces all existing variants with this set.</summary>
    public List<ProductVariantCell>? VariantMatrix { get; set; }

    // ── Extended product details (all optional; null leaves the column unchanged) ──
    public string? Material         { get; set; }
    public string? CareInstructions { get; set; }
    public string? FitType          { get; set; }
    public string? CountryOfOrigin  { get; set; }
    public string? WarrantyInfo     { get; set; }
    public string? DeliveryInfo     { get; set; }
    public List<ProductSpecDto>? Specifications { get; set; }

    public decimal? LengthCm  { get; set; }
    public decimal? WidthCm   { get; set; }
    public decimal? HeightCm  { get; set; }
    public decimal? WeightGm  { get; set; }
}

/// <summary>Seller product list item.</summary>
public class SellerProductListDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    [JsonPropertyName("mrp")]
    public decimal MRP { get; set; }
    [JsonPropertyName("sellingPrice")]
    public decimal SellingPrice { get; set; }
    [JsonPropertyName("discountPercent")]
    public decimal DiscountPct { get; set; }
    public int StockQuantity { get; set; }
    public int LowStockThreshold { get; set; }
    public string? PrimaryImage { get; set; }
    public bool IsApproved { get; set; }
    public DateTime CreatedAt { get; set; }
}

/// <summary>Seller product detail DTO.</summary>
public class SellerProductDetailDto
{
    public int Id { get; set; }
    public int ProductTypeId { get; set; }
    public int? BrandId { get; set; }
    public string? BrandName { get; set; }
    public int CategoryId { get; set; }
    public int SubCategoryId { get; set; }
    public List<string> Tags { get; set; } = [];
    public List<string> ImageUrls { get; set; } = [];
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    [JsonPropertyName("mrp")]
    public decimal MRP { get; set; }
    [JsonPropertyName("sellingPrice")]
    public decimal SellingPrice { get; set; }
    [JsonPropertyName("costPrice")]
    public decimal? CostPrice { get; set; }
    [JsonPropertyName("discountPercent")]
    public decimal DiscountPct { get; set; }
    public string? Gender { get; set; }
    public int StockQuantity { get; set; }
    public int LowStockThreshold { get; set; }
    public bool IsActive { get; set; }
    public bool IsApproved { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public List<ProductImageDto> Images { get; set; } = [];
    public List<ProductSizeDto> Sizes { get; set; } = [];
    public List<ProductColorDto> Colors { get; set; } = [];

    /// <summary>Flat per-variant rows so the wizard can rebuild its color×size matrix on edit.</summary>
    public List<ProductVariantCell> Variants { get; set; } = [];

    // ── Extended product details ──
    public string? Material         { get; set; }
    public string? CareInstructions { get; set; }
    public string? FitType          { get; set; }
    public string? CountryOfOrigin  { get; set; }
    public string? WarrantyInfo     { get; set; }
    public string? DeliveryInfo     { get; set; }
    public List<ProductSpecDto> Specifications { get; set; } = [];
}

/// <summary>Update inventory request.</summary>
public class UpdateInventoryRequest
{
    public int? StockQuantity { get; set; }
    public int? LowStockThreshold { get; set; }
}

/// <summary>Seller inventory item.</summary>
public class SellerInventoryDto
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int StockQuantity { get; set; }
    public int ReservedQuantity { get; set; }
    public int AvailableQuantity { get; set; }
    public int LowStockThreshold { get; set; }
    public bool IsLowStock { get; set; }
}

/// <summary>Seller order list item.</summary>
public class SellerOrderListDto
{
    public int OrderId { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string OrderStatus { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string? CustomerEmail { get; set; }
    public int ItemCount { get; set; }
    public DateTime CreatedAt { get; set; }
}

/// <summary>Seller order detail DTO.</summary>
public class SellerOrderDetailDto
{
    public int Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string PaymentStatus { get; set; } = string.Empty;
    public decimal FinalAmount { get; set; }
    public decimal DeliveryCharge { get; set; }
    public DateTime CreatedAt { get; set; }

    public List<SellerOrderItemDto> Items { get; set; } = [];
    public SellerOrderAddressDto? Address { get; set; }
}

/// <summary>Seller order item.</summary>
public class SellerOrderItemDto
{
    public int Id { get; set; }
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? SizeLabel { get; set; }
    public string? ColorName { get; set; }
    public int Quantity { get; set; }
    [JsonPropertyName("mrp")]
    public decimal MRP { get; set; }
    [JsonPropertyName("sellingPrice")]
    public decimal SellingPrice { get; set; }
    public decimal LineTotal { get; set; }
}

/// <summary>Seller order address.</summary>
public class SellerOrderAddressDto
{
    public string Name { get; set; } = string.Empty;
    public string Mobile { get; set; } = string.Empty;
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
}

/// <summary>Seller dashboard stats.</summary>
public class SellerDashboardDto
{
    public int TotalProducts { get; set; }
    public int ActiveProducts { get; set; }
    public int LowStockCount { get; set; }
    public int TotalOrders { get; set; }
    public decimal TotalSales { get; set; }
}

/// <summary>Image upload response.</summary>
public class ImageUploadResponse
{
    public string FileName { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
}

// ── Phase 3 — Seller onboarding & dashboard ───────────────────────────────

/// <summary>Seller business registration request — usp_Seller_Register.</summary>
public class SellerRegisterRequest
{
    public string BusinessName { get; set; } = string.Empty;
    public string GstNumber { get; set; } = string.Empty;
    public string PanNumber { get; set; } = string.Empty;
    public int BusinessAddressId { get; set; }
    public string BankAccountNumber { get; set; } = string.Empty;
    public string BankIfscCode { get; set; } = string.Empty;
    public string BankName { get; set; } = string.Empty;
}

/// <summary>Seller bank &amp; business update request — usp_Seller_UpdateProfile.</summary>
public class UpdateSellerBankRequest
{
    public string? BusinessName { get; set; }
    public string? BankAccountNumber { get; set; }
    public string? BankIfscCode { get; set; }
    public string? BankName { get; set; }
}

/// <summary>Request body for updating an order item's fulfilment status.</summary>
public class UpdateOrderStatusRequest
{
    public string OrderStatus { get; set; } = string.Empty;
}

/// <summary>Request body for seller-initiated order cancellation.</summary>
public class SellerCancelOrderRequest
{
    public string? CancellationReason { get; set; }
}

/// <summary>Result returned by usp_Seller_Order_Cancel — used internally for email dispatch.</summary>
public class SellerCancelOrderResult
{
    public int     BuyerUserId  { get; set; }
    public string  OrderNumber  { get; set; } = string.Empty;
    public decimal TotalAmount  { get; set; }
    public int     PaymentMode  { get; set; }
}

/// <summary>Seller analytics response — usp_Seller_Dashboard_GetAnalytics.</summary>
public class SellerAnalyticsDto
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public decimal TotalRevenue { get; set; }
    public int TotalOrders { get; set; }
    public int TotalUnitsSold { get; set; }
    public decimal AverageOrderValue { get; set; }
    public int NewOrders { get; set; }
    public int ProcessingOrders { get; set; }
    public int ShippedOrders { get; set; }
    public int DeliveredOrders { get; set; }
    public int CancelledOrders { get; set; }
}

/// <summary>Request body for triggering the analytics aggregation job.</summary>
public class AggregateAnalyticsRequest
{
    public DateTime AnalyticsDate { get; set; } = DateTime.UtcNow.Date;
}

// ── Phase 3 — Seller lifecycle (bank, warehouses, agreement, settlement, score) ──

public class SellerBankAccountDto
{
    public int BankAccountId { get; set; }
    public int SellerId { get; set; }
    public string AccountHolderName { get; set; } = string.Empty;
    public string BankName { get; set; } = string.Empty;
    public string AccountNumber { get; set; } = string.Empty;
    public string IfscCode { get; set; } = string.Empty;
    public string? BranchName { get; set; }
    public bool IsPrimary { get; set; }
    public bool IsVerified { get; set; }
    public DateTime? VerifiedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class AddSellerBankAccountRequest
{
    public string AccountHolderName { get; set; } = string.Empty;
    public string BankName { get; set; } = string.Empty;
    public string AccountNumber { get; set; } = string.Empty;
    public string IfscCode { get; set; } = string.Empty;
    public string? BranchName { get; set; }
    public bool IsPrimary { get; set; }
}

public class SellerWarehouseDto
{
    public int SellerWarehouseId { get; set; }
    public int SellerId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public string? ContactPhone { get; set; }
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public bool IsPrimary { get; set; }
}

public class UpsertSellerWarehouseRequest
{
    public int? SellerWarehouseId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ContactName { get; set; }
    public string? ContactPhone { get; set; }
    public string AddressLine1 { get; set; } = string.Empty;
    public string? AddressLine2 { get; set; }
    public string City { get; set; } = string.Empty;
    public string State { get; set; } = string.Empty;
    public string Pincode { get; set; } = string.Empty;
    public bool IsPrimary { get; set; }
}

public class AcceptVendorAgreementRequest
{
    public string Version { get; set; } = "1.0";
    public string? DocumentUrl { get; set; }
}

public class VendorAgreementDto
{
    public int AgreementId { get; set; }
    public int SellerId { get; set; }
    public string Version { get; set; } = string.Empty;
    public DateTime AcceptedAt { get; set; }
    public string? DocumentUrl { get; set; }
}

public class AdvanceOnboardingRequest
{
    public string Stage { get; set; } = string.Empty;
}

public class OnboardingStageDto
{
    public int SellerId { get; set; }
    public bool OnboardingCompleted { get; set; }
    public byte ApprovalStatus { get; set; }
    public string Stage { get; set; } = string.Empty;
}

public class SellerDocumentDto
{
    public int DocumentId { get; set; }
    public int SellerId { get; set; }
    public byte DocumentType { get; set; }
    public string DocumentUrl { get; set; } = string.Empty;
    public bool IsVerified { get; set; }
    public int? VerifiedBy { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UploadSellerDocumentRequest
{
    public byte DocumentType { get; set; }
    public string DocumentUrl { get; set; } = string.Empty;
}

public class SellerSettlementDto
{
    public int SettlementId { get; set; }
    public int SellerId { get; set; }
    public DateTime PeriodStart { get; set; }
    public DateTime PeriodEnd { get; set; }
    public decimal GrossSales { get; set; }
    public decimal CommissionAmount { get; set; }
    public decimal TdsAmount { get; set; }
    public decimal PenaltyAmount { get; set; }
    public decimal RefundAmount { get; set; }
    public decimal NetPayout { get; set; }
    public byte Status { get; set; }
    public DateTime? PaidAt { get; set; }
    public string? UtrNumber { get; set; }
    public int? BankAccountId { get; set; }
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class SellerSettlementLineDto
{
    public int SettlementLineId { get; set; }
    public int SettlementId { get; set; }
    public int OrderItemId { get; set; }
    public int OrderId { get; set; }
    public decimal GrossAmount { get; set; }
    public decimal CommissionAmount { get; set; }
    public decimal TdsAmount { get; set; }
    public decimal PenaltyAmount { get; set; }
    public decimal NetAmount { get; set; }
}

public class SellerSettlementDetailDto
{
    public SellerSettlementDto? Settlement { get; set; }
    public List<SellerSettlementLineDto> Lines { get; set; } = [];
}

public class CalculateSettlementRequest
{
    public DateTime PeriodStart { get; set; }
    public DateTime PeriodEnd { get; set; }
}

public class SellerPerformanceScoreDto
{
    public int PerformanceScoreId { get; set; }
    public int SellerId { get; set; }
    public DateTime SnapshotDate { get; set; }
    public int WindowDays { get; set; }
    public int OrdersTotal { get; set; }
    public int OrdersDelivered { get; set; }
    public int OrdersCancelled { get; set; }
    public int OrdersReturned { get; set; }
    public decimal OnTimeDispatchPct { get; set; }
    public decimal CancellationPct { get; set; }
    public decimal ReturnPct { get; set; }
    public decimal AvgRating { get; set; }
    public decimal CompositeScore { get; set; }
    public string Tier { get; set; } = "Bronze";
    public DateTime CreatedAt { get; set; }
}
