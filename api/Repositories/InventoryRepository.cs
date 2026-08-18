using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IInventoryRepository
{
    Task<List<WarehouseDto>> GetWarehousesAsync(int? sellerId, bool includeInactive);

    Task<List<StockRowDto>> GetStockByVariantAsync(int variantId);

    Task<(int StockId, int OnHand, int Reserved)> AdjustStockAsync(
        int variantId, int warehouseId, int quantityDelta, string? reason,
        byte movementType, string? referenceType, long? referenceId, int changedBy);

    Task<StockReserveResult> ReserveAsync(
        int variantId, int warehouseId, int quantity, int? userId,
        int? cartLineId, int ttlMinutes, int? changedBy);

    Task ReleaseReservationAsync(long reservationId, int? commitToOrderId, string? reason, int? changedBy);

    Task<(List<StockMatrixRowDto> Items, int Total)> GetStockMatrixAsync(
        int? sellerId, int? warehouseId, string? search, int page, int pageSize);

    Task<(List<LowStockRowDto> Items, int Total)> GetLowStockAlertsAsync(
        int? sellerId, int? warehouseId, int page, int pageSize);

    Task<(List<StockMovementDto> Items, int Total)> GetMovementsByVariantAsync(
        int variantId, int? warehouseId, int page, int pageSize);

    Task<int> InitiateTransferAsync(
        int variantId, int fromWarehouseId, int toWarehouseId, int quantity,
        string? reason, int initiatedBy);

    Task ReceiveTransferAsync(int transferId, int receivedBy);

    Task<int> ExpireDueReservationsAsync(int batchSize);

    Task WriteAuditAsync(string tableName, int recordId, string action,
        string? oldValues, string? newValues, int? changedBy, string? ipAddress);
}

public class InventoryRepository(IConfiguration config) : IInventoryRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<List<WarehouseDto>> GetWarehousesAsync(int? sellerId, bool includeInactive)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<WarehouseDto>(
            "usp_Inventory_Warehouse_GetAll",
            new { SellerId = sellerId, IncludeInactive = includeInactive },
            commandType: CommandType.StoredProcedure);
        return rows.AsList();
    }

    public async Task<List<StockRowDto>> GetStockByVariantAsync(int variantId)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<StockRowDto>(
            "usp_Inventory_Stock_GetByVariant",
            new { VariantId = variantId },
            commandType: CommandType.StoredProcedure);
        return rows.AsList();
    }

    public async Task<(int StockId, int OnHand, int Reserved)> AdjustStockAsync(
        int variantId, int warehouseId, int quantityDelta, string? reason,
        byte movementType, string? referenceType, long? referenceId, int changedBy)
    {
        using var db = Conn();
        var row = await db.QuerySingleAsync<(int StockId, int OnHand, int Reserved)>(
            "usp_Inventory_Stock_Adjust",
            new
            {
                VariantId     = variantId,
                WarehouseId   = warehouseId,
                QuantityDelta = quantityDelta,
                Reason        = reason,
                MovementType  = movementType,
                ReferenceType = referenceType,
                ReferenceId   = referenceId,
                ChangedBy     = changedBy
            },
            commandType: CommandType.StoredProcedure);
        return row;
    }

    public async Task<StockReserveResult> ReserveAsync(
        int variantId, int warehouseId, int quantity, int? userId,
        int? cartLineId, int ttlMinutes, int? changedBy)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<StockReserveResult>(
            "usp_Inventory_Stock_Reserve",
            new
            {
                VariantId   = variantId,
                WarehouseId = warehouseId,
                Quantity    = quantity,
                UserId      = userId,
                CartLineId  = cartLineId,
                TtlMinutes  = ttlMinutes,
                ChangedBy   = changedBy
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task ReleaseReservationAsync(long reservationId, int? commitToOrderId, string? reason, int? changedBy)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Inventory_Stock_ReleaseReservation",
            new
            {
                ReservationId   = reservationId,
                CommitToOrderId = commitToOrderId,
                Reason          = reason,
                ChangedBy       = changedBy
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<(List<StockMatrixRowDto> Items, int Total)> GetStockMatrixAsync(
        int? sellerId, int? warehouseId, string? search, int page, int pageSize)
    {
        using var db = Conn();
        using var multi = await db.QueryMultipleAsync(
            "usp_Inventory_StockMatrix_Get",
            new { SellerId = sellerId, WarehouseId = warehouseId, Search = search, Page = page, PageSize = pageSize },
            commandType: CommandType.StoredProcedure);
        var items = (await multi.ReadAsync<StockMatrixRowDto>()).AsList();
        var total = await multi.ReadFirstAsync<int>();
        return (items, total);
    }

    public async Task<(List<LowStockRowDto> Items, int Total)> GetLowStockAlertsAsync(
        int? sellerId, int? warehouseId, int page, int pageSize)
    {
        using var db = Conn();
        using var multi = await db.QueryMultipleAsync(
            "usp_Inventory_LowStock_Alerts",
            new { SellerId = sellerId, WarehouseId = warehouseId, Page = page, PageSize = pageSize },
            commandType: CommandType.StoredProcedure);
        var items = (await multi.ReadAsync<LowStockRowDto>()).AsList();
        var total = await multi.ReadFirstAsync<int>();
        return (items, total);
    }

    public async Task<(List<StockMovementDto> Items, int Total)> GetMovementsByVariantAsync(
        int variantId, int? warehouseId, int page, int pageSize)
    {
        using var db = Conn();
        using var multi = await db.QueryMultipleAsync(
            "usp_Inventory_Movement_GetByVariant",
            new { VariantId = variantId, WarehouseId = warehouseId, Page = page, PageSize = pageSize },
            commandType: CommandType.StoredProcedure);
        var items = (await multi.ReadAsync<StockMovementDto>()).AsList();
        var total = await multi.ReadFirstAsync<int>();
        return (items, total);
    }

    public async Task<int> InitiateTransferAsync(
        int variantId, int fromWarehouseId, int toWarehouseId, int quantity,
        string? reason, int initiatedBy)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<int>(
            "usp_Inventory_Transfer_Initiate",
            new
            {
                VariantId       = variantId,
                FromWarehouseId = fromWarehouseId,
                ToWarehouseId   = toWarehouseId,
                Quantity        = quantity,
                Reason          = reason,
                InitiatedBy     = initiatedBy
            },
            commandType: CommandType.StoredProcedure);
    }

    public async Task ReceiveTransferAsync(int transferId, int receivedBy)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Inventory_Transfer_Receive",
            new { TransferId = transferId, ReceivedBy = receivedBy },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<int> ExpireDueReservationsAsync(int batchSize)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<int>(
            "usp_Inventory_Reservation_ExpireDue",
            new { BatchSize = batchSize },
            commandType: CommandType.StoredProcedure);
    }

    public async Task WriteAuditAsync(string tableName, int recordId, string action,
        string? oldValues, string? newValues, int? changedBy, string? ipAddress)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            @"INSERT INTO [dbo].[AuditLogs] ([TableName],[RecordId],[Action],[OldValues],[NewValues],[ChangedBy],[IpAddress])
              VALUES (@TableName,@RecordId,@Action,@OldValues,@NewValues,@ChangedBy,@IpAddress);",
            new { TableName = tableName, RecordId = recordId, Action = action,
                  OldValues = oldValues, NewValues = newValues, ChangedBy = changedBy, IpAddress = ipAddress });
    }
}
