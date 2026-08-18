namespace ShopNShop.Api.DTOs;

// ── Warehouse ───────────────────────────────────────────────────────────────

public class WarehouseDto
{
    public int      WarehouseId  { get; set; }
    public string   Code         { get; set; } = string.Empty;
    public string   Name         { get; set; } = string.Empty;
    public int?     SellerId     { get; set; }
    public string?  SellerName   { get; set; }
    public string?  AddressLine1 { get; set; }
    public string?  AddressLine2 { get; set; }
    public string?  City         { get; set; }
    public string?  State        { get; set; }
    public string?  PinCode      { get; set; }
    public string?  Country      { get; set; }
    public bool     IsActive     { get; set; }
    public DateTime CreatedAt    { get; set; }
}

// ── Stock ───────────────────────────────────────────────────────────────────

public class StockRowDto
{
    public int      StockId        { get; set; }
    public int      VariantId      { get; set; }
    public int      WarehouseId    { get; set; }
    public string?  WarehouseCode  { get; set; }
    public string?  WarehouseName  { get; set; }
    public int      OnHand         { get; set; }
    public int      Reserved       { get; set; }
    public int      Available      { get; set; }
    public DateTime UpdatedAt      { get; set; }
}

public class StockMatrixRowDto
{
    public int     VariantId         { get; set; }
    public int     ProductId         { get; set; }
    public string  VariantSku        { get; set; } = string.Empty;
    public string  ProductName       { get; set; } = string.Empty;
    public string? Color             { get; set; }
    public string? Size              { get; set; }
    public int     LowStockThreshold { get; set; }
    public int?    SellerId          { get; set; }
    public string? SellerName        { get; set; }
    public int?    WarehouseId       { get; set; }
    public string? WarehouseCode     { get; set; }
    public string? WarehouseName     { get; set; }
    public int     OnHand            { get; set; }
    public int     Reserved          { get; set; }
    public int     Available         { get; set; }
}

public class LowStockRowDto
{
    public int     VariantId         { get; set; }
    public int     ProductId         { get; set; }
    public string  VariantSku        { get; set; } = string.Empty;
    public string? Color             { get; set; }
    public string? Size              { get; set; }
    public int     LowStockThreshold { get; set; }
    public string  ProductName       { get; set; } = string.Empty;
    public int?    SellerId          { get; set; }
    public string? SellerName        { get; set; }
    public int     TotalOnHand       { get; set; }
    public int     TotalReserved     { get; set; }
    public int     TotalAvailable    { get; set; }
}

// ── Movements ───────────────────────────────────────────────────────────────

public class StockMovementDto
{
    public long     MovementId      { get; set; }
    public int      VariantId       { get; set; }
    public int      WarehouseId     { get; set; }
    public string?  WarehouseCode   { get; set; }
    public string?  WarehouseName   { get; set; }
    public byte     MovementType    { get; set; }
    public int      QuantityDelta   { get; set; }
    public int      ReservedDelta   { get; set; }
    public string?  Reason          { get; set; }
    public string?  ReferenceType   { get; set; }
    public long?    ReferenceId     { get; set; }
    public int?     ChangedBy       { get; set; }
    public string?  ChangedByEmail  { get; set; }
    public DateTime ChangedAt       { get; set; }
}

// ── Requests ────────────────────────────────────────────────────────────────

public class StockAdjustRequest
{
    public int     VariantId     { get; set; }
    public int     WarehouseId   { get; set; }
    public int     QuantityDelta { get; set; }
    public string? Reason        { get; set; }
    /// <summary>Default 2 = Adjustment. 1=Receipt, 6=Return.</summary>
    public byte    MovementType  { get; set; } = 2;
}

public class StockReserveRequest
{
    public int  VariantId   { get; set; }
    public int  WarehouseId { get; set; }
    public int  Quantity    { get; set; }
    public int? CartLineId  { get; set; }
    public int  TtlMinutes  { get; set; } = 15;
}

public class StockReleaseRequest
{
    public long    ReservationId   { get; set; }
    public int?    CommitToOrderId { get; set; }
    public string? Reason          { get; set; }
}

public class StockReserveResult
{
    public long     ReservationId { get; set; }
    public DateTime ExpiresAt     { get; set; }
}

public class StockTransferInitiateRequest
{
    public int     VariantId       { get; set; }
    public int     FromWarehouseId { get; set; }
    public int     ToWarehouseId   { get; set; }
    public int     Quantity        { get; set; }
    public string? Reason          { get; set; }
}
