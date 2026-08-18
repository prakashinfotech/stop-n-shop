namespace ShopNShop.Api.DTOs;

public class AdminStatsDto
{
    public int     TotalBuyers              { get; set; }
    public int     TotalUsers               => TotalBuyers;   // legacy alias
    public int     TotalSellers             { get; set; }
    public int     PendingSellerApprovals   { get; set; }
    public int     TotalProducts            { get; set; }
    public int     PendingProductApprovals  { get; set; }
    public int     TotalOrders              { get; set; }
    public decimal TotalRevenue             { get; set; }
    public int     UnfulfilledOrders        { get; set; }
    public int     RejectedOrderItems       { get; set; }
}

public class AdminSellerDto
{
    public int      Id              { get; set; }
    public string   BusinessName    { get; set; } = string.Empty;
    public string?  OwnerName       { get; set; }
    public string?  Email           { get; set; }
    public string?  PhoneNumber     { get; set; }
    public byte     ApprovalStatus  { get; set; }      // 1=Pending, 2=Approved, 3=Rejected, 4=Suspended
    public bool     IsApproved      => ApprovalStatus == 2;
    public bool     IsActive        { get; set; }
    public System.DateTime CreatedAt { get; set; }
}

public class AdminProductDto
{
    public int      Id             { get; set; }
    public string   Name           { get; set; } = string.Empty;
    public string?  SellerName     { get; set; }
    public string?  BrandName      { get; set; }
    public string?  CategoryName   { get; set; }
    public decimal  SellingPrice   { get; set; }
    public decimal  MRP            { get; set; }
    public byte     ApprovalStatus { get; set; }
    public bool     IsApproved     => ApprovalStatus == 2;
    public bool     IsActive       { get; set; }
    public string?  PrimaryImage   { get; set; }
    public System.DateTime CreatedAt { get; set; }
}

public class AdminUserDto
{
    public int      Id              { get; set; }
    public string?  FirstName       { get; set; }
    public string?  LastName        { get; set; }
    public string   Name            => $"{FirstName} {LastName}".Trim();
    public string?  Email           { get; set; }
    public string?  Mobile          { get; set; } = string.Empty;
    public string   Role            { get; set; } = string.Empty;
    public bool     IsActive        { get; set; }
    public System.DateTime CreatedAt { get; set; }
}

public class AdminOrderDto
{
    public int      Id            { get; set; }
    public string   OrderNumber   { get; set; } = string.Empty;
    public string   CustomerName  { get; set; } = string.Empty;
    public string?  SellerName    { get; set; }
    public string   Status        { get; set; } = string.Empty;
    public decimal  FinalAmount   { get; set; }
    public System.DateTime CreatedAt { get; set; }
}

public class AdminReviewDto
{
    public int      Id            { get; set; }
    public int      ProductId     { get; set; }
    public string?  ProductName   { get; set; }
    public string?  ReviewerName  { get; set; }
    public byte     Rating        { get; set; }
    public string?  Comment       { get; set; }
    public bool     IsApproved    { get; set; }
    public System.DateTime CreatedAt { get; set; }
}

public record RejectReasonRequest(string? Reason);

public record SuspendUserRequest(string? Reason);
public record ForceCancelOrderRequest(string Reason);
public record ManualRefundRequest(decimal RefundAmount, string Reason, string? GatewayRef);

public record UpdateCouponRequest(
    string  CouponCode,
    string  OfferName,
    byte    OfferType,
    decimal DiscountValue,
    decimal MinOrderValue,
    decimal? MaxDiscountCap,
    DateTime StartDate,
    DateTime EndDate,
    byte    ApplicableOn,
    int?    EntityId,
    byte    UsageLimitPerUser);

public class AdminAuditEntryDto
{
    public long      AuditId            { get; set; }
    public string    TableName          { get; set; } = string.Empty;
    public int       RecordId           { get; set; }
    public string    Action             { get; set; } = string.Empty;
    public string?   OldValues          { get; set; }
    public string?   NewValues          { get; set; }
    public int?      ChangedBy          { get; set; }
    public DateTime  ChangedAt          { get; set; }
    public string?   IpAddress          { get; set; }
    public string?   ChangedByEmail     { get; set; }
    public string?   ChangedByFirstName { get; set; }
    public string?   ChangedByLastName  { get; set; }
    public string    ChangedByName      => $"{ChangedByFirstName} {ChangedByLastName}".Trim();
}

public class AdminSellerScoreDto
{
    public int      SellerId             { get; set; }
    public DateTime FromDate             { get; set; }
    public DateTime ToDate               { get; set; }
    public int      TotalOrders          { get; set; }
    public int      DeliveredOrders      { get; set; }
    public int      CancelledOrders      { get; set; }
    public decimal  Gmv                  { get; set; }
    public decimal  AverageRating        { get; set; }
    public int      ReviewCount          { get; set; }
    public decimal  DeliveryRatePct      { get; set; }
    public decimal  CancellationRatePct  { get; set; }
}
