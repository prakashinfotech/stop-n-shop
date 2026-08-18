using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface ISellerOrderService
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

public class SellerOrderService(ISellerOrderRepository repo, IEmailService emailService, IAuthRepository authRepo) : ISellerOrderService
{
    public Task<PagedResult<SellerOrderListDto>> GetOrdersAsync(int sellerId, string? orderStatus, int page, int pageSize) =>
        repo.GetOrdersAsync(sellerId, orderStatus, page, pageSize);

    public Task<SellerOrderDetailDto?> GetOrderDetailAsync(int sellerId, int orderId) =>
        repo.GetOrderDetailAsync(sellerId, orderId);

    public Task UpdateOrderStatusAsync(int orderItemId, int sellerId, string orderStatus) =>
        repo.UpdateOrderStatusAsync(orderItemId, sellerId, orderStatus);

    public async Task<dynamic?> UpdateOrderStatusNewAsync(int orderId, int sellerId, int newStatus)
    {
        var result = await repo.UpdateOrderStatusNewAsync(orderId, sellerId, newStatus);

        if (result is not null)
        {
            _ = Task.Run(async () =>
            {
                try
                {
                    var order = await GetOrderDetailAsync(sellerId, orderId);
                    if (order is not null)
                    {
                        var profile = await authRepo.GetProfileAsync((int)result.UserId);
                        if (profile is not null)
                        {
                            var name = $"{profile.FirstName} {profile.LastName}".Trim();
                            var statusLabel = GetStatusLabel(newStatus);
                            await emailService.SendOrderStatusUpdateAsync(
                                profile.Email ?? string.Empty,
                                string.IsNullOrWhiteSpace(name) ? "Valued Customer" : name,
                                (string)result.OrderNumber,
                                statusLabel);
                        }
                    }
                }
                catch { /* swallow — email must never break order flow */ }
            });
        }

        return result;
    }

    public Task<SellerCancelOrderResult> CancelOrderAsync(int orderId, int sellerId, string? reason) =>
        repo.CancelOrderAsync(orderId, sellerId, reason);

    private static string GetStatusLabel(int status) => status switch
    {
        1 => "Pending",
        2 => "Confirmed",
        3 => "Processing",
        4 => "Shipped",
        5 => "Delivered",
        6 => "Cancelled",
        _ => status.ToString()
    };

    // ── Fulfilment queue (W-A) ───────────────────────────────────────────
    public Task<(List<SellerQueueItemDto> Items, int Total)> GetQueueAsync(int sellerId, string statusFilter, int page, int pageSize) =>
        repo.GetQueueAsync(sellerId, statusFilter, page, pageSize);

    public Task<SellerQueueCountsDto> GetQueueCountsAsync(int sellerId) =>
        repo.GetQueueCountsAsync(sellerId);

    public Task<SellerActionResultDto> ConfirmItemAsync(int orderItemId, int sellerId) =>
        repo.ConfirmItemAsync(orderItemId, sellerId);

    public Task<SellerActionResultDto> RejectItemAsync(int orderItemId, int sellerId, string reason) =>
        repo.RejectItemAsync(orderItemId, sellerId, reason);

    public Task<SellerActionResultDto> UpdateItemStatusAsync(int orderItemId, int sellerId, byte newStatus) =>
        repo.UpdateItemStatusAsync(orderItemId, sellerId, newStatus);

    public Task<SellerLabelDataDto> GetLabelDataAsync(int orderItemId, int sellerId) =>
        repo.GetLabelDataAsync(orderItemId, sellerId);
}
