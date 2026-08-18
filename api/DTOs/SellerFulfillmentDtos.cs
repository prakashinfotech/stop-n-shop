namespace ShopNShop.Api.DTOs;

/// <summary>One row in the seller's order-fulfilment queue.</summary>
public class SellerQueueItemDto
{
    public int       OrderItemId      { get; set; }
    public int       OrderId          { get; set; }
    public string    OrderNumber      { get; set; } = string.Empty;
    public int       ProductId        { get; set; }
    public int       VariantId        { get; set; }
    public string    ProductName      { get; set; } = string.Empty;
    public string?   VariantSnapshot  { get; set; }
    public int       Quantity         { get; set; }
    public decimal   UnitPrice        { get; set; }
    public decimal   TotalPrice       { get; set; }
    public byte      OrderStatus      { get; set; }   // 1 Placed, 2 Confirmed, 3 Packed, 4 Dispatched, 5 Delivered, 6 Cancelled, 7 Returned, 8 Rejected
    public DateTime  CreatedAt        { get; set; }
    public DateTime? ConfirmedAt      { get; set; }
    public DateTime? RejectedAt       { get; set; }
    public string?   RejectionReason  { get; set; }
    public byte      PaymentMode      { get; set; }
    public byte      PaymentStatus    { get; set; }
    public string?   BuyerName        { get; set; }
    public string?   BuyerMobile      { get; set; }
    public string?   BuyerCity        { get; set; }
    public string?   BuyerPincode     { get; set; }
    public string?   PrimaryImageUrl  { get; set; }
}

public record SellerRejectItemRequest(string Reason);

/// <summary>Body for the forward-only status transition endpoint.
/// Valid <c>NewStatus</c> values: 3 Packed, 4 Dispatched, 9 OutForDelivery, 5 Delivered.
/// The SP enforces which transitions are legal from the item's current state.</summary>
public record SellerUpdateItemStatusRequest(byte NewStatus);

public class SellerActionResultDto
{
    public int     OrderItemId { get; set; }
    public byte    OrderStatus { get; set; }
    public string? OrderNumber { get; set; }
}

/// <summary>Per-tab counters for the seller fulfilment queue. Returned in one
/// roundtrip so the UI can render badges without N+1 queries.</summary>
public class SellerQueueCountsDto
{
    public int Placed    { get; set; }
    public int Confirmed { get; set; }
    public int Rejected  { get; set; }
    public int Fulfilled { get; set; }
    public int All       { get; set; }
}
