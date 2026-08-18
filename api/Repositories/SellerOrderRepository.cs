using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface ISellerOrderRepository
{
    Task<PagedResult<SellerOrderListDto>> GetOrdersAsync(int sellerId, string? orderStatus, int page, int pageSize);
    Task<SellerOrderDetailDto?> GetOrderDetailAsync(int sellerId, int orderId);
    Task UpdateOrderStatusAsync(int orderItemId, int sellerId, string orderStatus);
    Task<dynamic?> UpdateOrderStatusNewAsync(int orderId, int sellerId, int newStatus);
    Task<SellerCancelOrderResult> CancelOrderAsync(int orderId, int sellerId, string? reason);

    Task<(List<SellerQueueItemDto> Items, int Total)> GetQueueAsync(int sellerId, string statusFilter, int page, int pageSize);
    Task<SellerQueueCountsDto> GetQueueCountsAsync(int sellerId);
    Task<SellerActionResultDto> ConfirmItemAsync(int orderItemId, int sellerId);
    Task<SellerActionResultDto> RejectItemAsync(int orderItemId, int sellerId, string reason);
    Task<SellerActionResultDto> UpdateItemStatusAsync(int orderItemId, int sellerId, byte newStatus);
    Task<SellerLabelDataDto> GetLabelDataAsync(int orderItemId, int sellerId);
}

public class SellerOrderRepository(IConfiguration config) : ISellerOrderRepository
{
    private SqlConnection Conn() =>
        new(config.GetConnectionString("ShopNShop"));

    public async Task<PagedResult<SellerOrderListDto>> GetOrdersAsync(int sellerId, string? orderStatus, int page, int pageSize)
    {
        using var db = Conn();

        // Convert string status to numeric (1-7) or null
        byte? numericStatus = orderStatus switch
        {
            "Pending" => 1,
            "Confirmed" => 2,
            "Processing" => 3,
            "Shipped" => 4,
            "Delivered" => 5,
            "Cancelled" => 6,
            "Returned" => 7,
            _ => null
        };

        var rows = await db.QueryAsync<OrderListRow>(
            "usp_Seller_Order_GetAll",
            new
            {
                SellerId    = sellerId,
                OrderStatus = numericStatus,
                PageNumber  = page,
                PageSize    = pageSize
            },
            commandType: System.Data.CommandType.StoredProcedure);

        var list = rows.ToList();

        // SP returns one row per OrderItem — collapse to one entry per Order for the seller list view.
        var items = list
            .GroupBy(r => r.OrderId)
            .Select(g =>
            {
                var head = g.First();
                return new SellerOrderListDto
                {
                    OrderId       = head.OrderId,
                    OrderNumber   = head.OrderNumber,
                    OrderStatus   = MapOrderStatus(head.OrderStatus),
                    TotalAmount   = head.TotalAmount,
                    CustomerName  = string.Join(' ',
                                        new[] { head.FirstName, head.LastName }
                                        .Where(s => !string.IsNullOrWhiteSpace(s))),
                    CustomerEmail = head.Email,
                    ItemCount     = g.Count(),
                    CreatedAt     = head.OrderDate,
                };
            })
            .ToList();

        return new PagedResult<SellerOrderListDto>
        {
            Items      = items,
            TotalCount = list.Count > 0 ? list[0].TotalCount : 0,
            PageNo     = page,
            PageSize   = pageSize
        };
    }

    private static string MapOrderStatus(byte code) => code switch
    {
        1 => "Pending",
        2 => "Confirmed",
        3 => "Processing",
        4 => "Shipped",
        5 => "Delivered",
        6 => "Cancelled",
        7 => "Returned",
        _ => "Unknown",
    };

    public async Task<SellerOrderDetailDto?> GetOrderDetailAsync(int sellerId, int orderId)
    {
        using var db = Conn();

        using var multi = await db.QueryMultipleAsync(
            "sp_SellerGetOrderDetail",
            new { SellerId = sellerId, OrderId = orderId },
            commandType: System.Data.CommandType.StoredProcedure);

        var order = await multi.ReadSingleOrDefaultAsync<SellerOrderDetailDto>();
        if (order is null) return null;

        order.Items   = (await multi.ReadAsync<SellerOrderItemDto>()).ToList();
        order.Address = await multi.ReadSingleOrDefaultAsync<SellerOrderAddressDto>();

        return order;
    }

    public async Task UpdateOrderStatusAsync(int orderItemId, int sellerId, string orderStatus)
    {
        // Convert string status to numeric. Sellers may only progress to Processing/Shipped/Delivered;
        // the SP itself rejects other transitions, so we surface a clean message here for invalid picks.
        byte newStatus = orderStatus switch
        {
            "Processing" => 3,
            "Shipped" => 4,
            "Delivered" => 5,
            "Pending" or "Confirmed" or "Cancelled" or "Returned" =>
                throw new InvalidOperationException(
                    $"Sellers can only move an order to Processing, Shipped, or Delivered. Use Cancel to cancel an order."),
            _ => throw new InvalidOperationException($"Invalid order status: {orderStatus}")
        };

        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Seller_Order_UpdateStatus",
            new { OrderId = orderItemId, SellerId = sellerId, NewStatus = newStatus, UpdatedBy = sellerId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<dynamic?> UpdateOrderStatusNewAsync(int orderId, int sellerId, int newStatus)
    {
        using var db = Conn();
        try
        {
            return await db.QuerySingleOrDefaultAsync<dynamic>(
                "usp_SellerOrder_UpdateStatus",
                new { OrderId = orderId, SellerId = sellerId, NewStatus = newStatus },
                commandType: System.Data.CommandType.StoredProcedure);
        }
        catch (SqlException ex)
        {
            throw new InvalidOperationException(ex.Message);
        }
    }

    public async Task<SellerCancelOrderResult> CancelOrderAsync(int orderId, int sellerId, string? reason)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<SellerCancelOrderResult>(
            "usp_Seller_Order_Cancel",
            new { OrderId = orderId, SellerId = sellerId, CancellationReason = reason },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    private sealed class OrderListRow
    {
        public int OrderId { get; set; }
        public string OrderNumber { get; set; } = string.Empty;
        public byte OrderStatus { get; set; }
        public decimal TotalAmount { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Email { get; set; }
        public DateTime OrderDate { get; set; }
        public int TotalCount { get; set; }
    }

    // ── Fulfilment queue (W-A) ────────────────────────────────────────────────

    private sealed class QueueRow : SellerQueueItemDto { public int TotalCount { get; set; } }

    public async Task<(List<SellerQueueItemDto> Items, int Total)> GetQueueAsync(int sellerId, string statusFilter, int page, int pageSize)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<QueueRow>(
            "usp_Seller_OrderItem_GetQueue",
            new { SellerId = sellerId, StatusFilter = statusFilter, Page = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<SellerQueueItemDto>().ToList(), total);
    }

    public async Task<SellerQueueCountsDto> GetQueueCountsAsync(int sellerId)
    {
        using var db = Conn();
        // SUM(...) over an empty result set returns NULL — coalesce to a
        // zero-filled DTO so the UI always gets the same shape.
        var row = await db.QuerySingleOrDefaultAsync<SellerQueueCountsDto>(
            "usp_Seller_OrderItem_GetQueueCounts",
            new { SellerId = sellerId },
            commandType: System.Data.CommandType.StoredProcedure);
        return row ?? new SellerQueueCountsDto();
    }

    public async Task<SellerActionResultDto> ConfirmItemAsync(int orderItemId, int sellerId)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<SellerActionResultDto>(
            "usp_Seller_OrderItem_Confirm",
            new { OrderItemId = orderItemId, SellerId = sellerId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<SellerActionResultDto> RejectItemAsync(int orderItemId, int sellerId, string reason)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<SellerActionResultDto>(
            "usp_Seller_OrderItem_Reject",
            new { OrderItemId = orderItemId, SellerId = sellerId, Reason = reason },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<SellerActionResultDto> UpdateItemStatusAsync(int orderItemId, int sellerId, byte newStatus)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<SellerActionResultDto>(
            "usp_Seller_OrderItem_UpdateStatus",
            new { OrderItemId = orderItemId, SellerId = sellerId, NewStatus = newStatus },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<SellerLabelDataDto> GetLabelDataAsync(int orderItemId, int sellerId)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<SellerLabelDataDto>(
            "usp_Seller_OrderItem_GetLabelData",
            new { OrderItemId = orderItemId, SellerId = sellerId },
            commandType: System.Data.CommandType.StoredProcedure);
    }
}
