using System.Text.Json;
using FluentValidation;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IInventoryService
{
    Task<List<WarehouseDto>>                                     GetWarehousesAsync(int? sellerId, bool includeInactive);
    Task<List<StockRowDto>>                                      GetStockByVariantAsync(int variantId);
    Task<(List<StockMatrixRowDto> Items, int Total)>             GetStockMatrixAsync(int? sellerId, int? warehouseId, string? search, int page, int pageSize);
    Task<(List<LowStockRowDto>    Items, int Total)>             GetLowStockAlertsAsync(int? sellerId, int? warehouseId, int page, int pageSize);
    Task<(List<StockMovementDto>  Items, int Total)>             GetMovementsByVariantAsync(int variantId, int? warehouseId, int page, int pageSize);

    Task<(int OnHand, int Reserved)> AdjustStockAsync(StockAdjustRequest req, int changedBy, string? ip);
    Task<StockReserveResult>         ReserveAsync(StockReserveRequest req, int? userId, int? changedBy, string? ip);
    Task                              ReleaseAsync(StockReleaseRequest req, int? changedBy, string? ip);
    Task<int>                         InitiateTransferAsync(StockTransferInitiateRequest req, int initiatedBy, string? ip);
    Task                              ReceiveTransferAsync(int transferId, int receivedBy, string? ip);
}

/// <summary>
/// All mutating inventory ops route through this service so each one records
/// an AuditLogs entry via <see cref="IInventoryRepository.WriteAuditAsync"/>.
/// </summary>
public class InventoryService(
    IInventoryRepository repo,
    IValidator<StockAdjustRequest> adjustValidator,
    IValidator<StockReserveRequest> reserveValidator,
    IValidator<StockTransferInitiateRequest> transferValidator)
    : IInventoryService
{
    private static readonly JsonSerializerOptions JsonOpts = new() { WriteIndented = false };

    private Task LogAsync(string table, int recordId, string verb, object? payload, int? changedBy, string? ip)
        => repo.WriteAuditAsync(
            tableName: table,
            recordId:  recordId,
            action:    "UPDATE",  // AuditLogs.Action is CHECK-constrained to INSERT/UPDATE/DELETE
            oldValues: null,
            newValues: JsonSerializer.Serialize(new { verb, data = payload }, JsonOpts),
            changedBy: changedBy,
            ipAddress: ip);

    // ── Reads ────────────────────────────────────────────────────────────────

    public Task<List<WarehouseDto>> GetWarehousesAsync(int? sellerId, bool includeInactive)
        => repo.GetWarehousesAsync(sellerId, includeInactive);

    public Task<List<StockRowDto>> GetStockByVariantAsync(int variantId)
        => repo.GetStockByVariantAsync(variantId);

    public Task<(List<StockMatrixRowDto> Items, int Total)> GetStockMatrixAsync(
        int? sellerId, int? warehouseId, string? search, int page, int pageSize)
        => repo.GetStockMatrixAsync(sellerId, warehouseId, search, page, pageSize);

    public Task<(List<LowStockRowDto> Items, int Total)> GetLowStockAlertsAsync(
        int? sellerId, int? warehouseId, int page, int pageSize)
        => repo.GetLowStockAlertsAsync(sellerId, warehouseId, page, pageSize);

    public Task<(List<StockMovementDto> Items, int Total)> GetMovementsByVariantAsync(
        int variantId, int? warehouseId, int page, int pageSize)
        => repo.GetMovementsByVariantAsync(variantId, warehouseId, page, pageSize);

    // ── Writes ───────────────────────────────────────────────────────────────

    public async Task<(int OnHand, int Reserved)> AdjustStockAsync(StockAdjustRequest req, int changedBy, string? ip)
    {
        await adjustValidator.ValidateAndThrowAsync(req);

        var result = await repo.AdjustStockAsync(
            req.VariantId, req.WarehouseId, req.QuantityDelta, req.Reason,
            req.MovementType, referenceType: "Manual", referenceId: null, changedBy: changedBy);

        await LogAsync("Stock", result.StockId, "ADJUST_STOCK", req, changedBy, ip);
        return (result.OnHand, result.Reserved);
    }

    public async Task<StockReserveResult> ReserveAsync(StockReserveRequest req, int? userId, int? changedBy, string? ip)
    {
        await reserveValidator.ValidateAndThrowAsync(req);

        var res = await repo.ReserveAsync(
            req.VariantId, req.WarehouseId, req.Quantity, userId,
            req.CartLineId, req.TtlMinutes, changedBy);

        await LogAsync("StockReservations", (int)res.ReservationId, "RESERVE_STOCK", req, changedBy, ip);
        return res;
    }

    public async Task ReleaseAsync(StockReleaseRequest req, int? changedBy, string? ip)
    {
        await repo.ReleaseReservationAsync(req.ReservationId, req.CommitToOrderId, req.Reason, changedBy);
        await LogAsync("StockReservations", (int)req.ReservationId,
            req.CommitToOrderId.HasValue ? "COMMIT_RESERVATION" : "RELEASE_RESERVATION",
            req, changedBy, ip);
    }

    public async Task<int> InitiateTransferAsync(StockTransferInitiateRequest req, int initiatedBy, string? ip)
    {
        await transferValidator.ValidateAndThrowAsync(req);
        var id = await repo.InitiateTransferAsync(
            req.VariantId, req.FromWarehouseId, req.ToWarehouseId, req.Quantity, req.Reason, initiatedBy);
        await LogAsync("StockTransfers", id, "TRANSFER_INITIATE", req, initiatedBy, ip);
        return id;
    }

    public async Task ReceiveTransferAsync(int transferId, int receivedBy, string? ip)
    {
        await repo.ReceiveTransferAsync(transferId, receivedBy);
        await LogAsync("StockTransfers", transferId, "TRANSFER_RECEIVE", null, receivedBy, ip);
    }
}

// ── Validators ─────────────────────────────────────────────────────────────

public class StockAdjustRequestValidator : AbstractValidator<StockAdjustRequest>
{
    public StockAdjustRequestValidator()
    {
        RuleFor(x => x.VariantId).GreaterThan(0);
        RuleFor(x => x.WarehouseId).GreaterThan(0);
        RuleFor(x => x.QuantityDelta).NotEqual(0).WithMessage("QuantityDelta must be non-zero.");
        RuleFor(x => x.MovementType).Must(v => v is 1 or 2 or 6).WithMessage("MovementType must be 1 (Receipt), 2 (Adjustment) or 6 (Return).");
        RuleFor(x => x.Reason).MaximumLength(500);
    }
}

public class StockReserveRequestValidator : AbstractValidator<StockReserveRequest>
{
    public StockReserveRequestValidator()
    {
        RuleFor(x => x.VariantId).GreaterThan(0);
        RuleFor(x => x.WarehouseId).GreaterThan(0);
        RuleFor(x => x.Quantity).GreaterThan(0);
        RuleFor(x => x.TtlMinutes).InclusiveBetween(1, 240).WithMessage("TtlMinutes must be between 1 and 240.");
    }
}

public class StockTransferInitiateRequestValidator : AbstractValidator<StockTransferInitiateRequest>
{
    public StockTransferInitiateRequestValidator()
    {
        RuleFor(x => x.VariantId).GreaterThan(0);
        RuleFor(x => x.FromWarehouseId).GreaterThan(0);
        RuleFor(x => x.ToWarehouseId).GreaterThan(0);
        RuleFor(x => x.Quantity).GreaterThan(0);
        RuleFor(x => x).Must(r => r.FromWarehouseId != r.ToWarehouseId)
                       .WithMessage("From and To warehouses must differ.");
        RuleFor(x => x.Reason).MaximumLength(500);
    }
}
