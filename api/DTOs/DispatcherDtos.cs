namespace ShopNShop.Api.DTOs;

/// <summary>Profile read for the dispatcher portal.</summary>
public class DispatcherProfileDto
{
    public int       DispatcherId            { get; set; }
    public int       UserId                  { get; set; }
    public string    EmployeeCode            { get; set; } = string.Empty;
    public string?   VehicleNumber           { get; set; }
    public string?   VehicleType             { get; set; }
    public string?   LicenseNumber           { get; set; }
    public int?      BaseWarehouseId         { get; set; }
    public string?   BaseWarehouseName       { get; set; }
    public string?   FirstName               { get; set; }
    public string?   LastName                { get; set; }
    public string?   Email                   { get; set; }
    public string?   Mobile                  { get; set; }
    public DateTime  JoinedAt                { get; set; }
    public bool      IsActive                { get; set; }
    public string?   AssignedWarehousesLabel { get; set; }
}

/// <summary>One row on the dispatcher's pickup queue. Mixes status-3 (claimable)
/// and status-10 (already claimed by THIS dispatcher, awaiting confirm).</summary>
public class DispatcherQueueItemDto
{
    public int       OrderItemId           { get; set; }
    public int       OrderId               { get; set; }
    public string    OrderNumber           { get; set; } = string.Empty;
    public string    ProductName           { get; set; } = string.Empty;
    public string?   VariantSnapshot       { get; set; }
    public int       Quantity              { get; set; }
    public decimal   TotalPrice            { get; set; }
    public byte      OrderStatus           { get; set; }     // 3 = claimable, 10 = already claimed
    public DateTime  OrderItemCreatedAt    { get; set; }
    public int       WarehouseId           { get; set; }
    public string?   WarehouseCode         { get; set; }
    public string?   WarehouseName         { get; set; }
    public string?   WarehouseCity         { get; set; }
    public byte      PaymentMode           { get; set; }
    public byte      PaymentStatus         { get; set; }
    public decimal?  CodAmount             { get; set; }     // non-null on COD-unpaid only
    public string?   BuyerName             { get; set; }
    public string?   BuyerMobile           { get; set; }
    public string?   BuyerAddressLine1     { get; set; }
    public string?   BuyerCity             { get; set; }
    public string?   BuyerState            { get; set; }
    public string?   BuyerPincode          { get; set; }
    public int?      AssignmentId          { get; set; }     // non-null = already claimed
    public byte?     AssignmentStatus      { get; set; }
}

/// <summary>Active assignment for the in-transit list. Same shape as queue
/// rows but always has an AssignmentId.</summary>
public class DispatcherAssignmentDto
{
    public int       AssignmentId       { get; set; }
    public byte      AssignmentStatus   { get; set; }
    public DateTime  AssignedAt         { get; set; }
    public DateTime? PickedUpAt         { get; set; }
    public DateTime? OutForDeliveryAt   { get; set; }
    public byte      AttemptNumber      { get; set; }
    public decimal?  CodAmount          { get; set; }
    public int       OrderItemId        { get; set; }
    public int       OrderId            { get; set; }
    public string    OrderNumber        { get; set; } = string.Empty;
    public string    ProductName        { get; set; } = string.Empty;
    public string?   VariantSnapshot    { get; set; }
    public int       Quantity           { get; set; }
    public decimal   TotalPrice         { get; set; }
    public byte      OrderStatus        { get; set; }
    public string?   WarehouseCode      { get; set; }
    public string?   WarehouseName      { get; set; }
    public string?   BuyerName          { get; set; }
    public string?   BuyerMobile        { get; set; }
    public string?   BuyerAddressLine1  { get; set; }
    public string?   BuyerCity          { get; set; }
    public string?   BuyerState         { get; set; }
    public string?   BuyerPincode       { get; set; }
    public byte      PaymentMode        { get; set; }
    public byte      PaymentStatus      { get; set; }
}

/// <summary>Result envelope from Pickup_Claim.</summary>
public class DispatcherClaimResultDto
{
    public int    AssignmentId { get; set; }
    public int    OrderItemId  { get; set; }
    public byte   OrderStatus  { get; set; }
    public string OrderNumber  { get; set; } = string.Empty;
    public int    WarehouseId  { get; set; }
}

/// <summary>Internal — what SendOtp SP returns so the service can SMS the OTP.
/// The OTP itself is NEVER serialised back to the dispatcher API response.</summary>
public class DispatcherSendOtpResultDto
{
    public string  Otp         { get; set; } = string.Empty;
    public string  OrderNumber { get; set; } = string.Empty;
    public string? BuyerName   { get; set; }
    public string? BuyerMobile { get; set; }
}

/// <summary>Body for completing a delivery (verify OTP + proof + COD).</summary>
public record DispatcherCompleteDeliveryRequest(
    string         Otp,
    string?        ProofPhotoUrl,
    decimal?       GpsLat,
    decimal?       GpsLng,
    decimal?       CodAmount);
