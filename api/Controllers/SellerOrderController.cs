using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Seller order management — view orders and details.</summary>
[ApiController]
[Route("api/seller/orders")]
[Produces("application/json")]
[Authorize(Roles = "Seller")]
public class SellerOrderController(
    ISellerOrderService svc,
    IEmailService       emailService,
    IAuthService        authService,
    ILogger<SellerOrderController> logger) : ControllerBase
{
    /// <summary>Get paginated list of seller's orders.</summary>
    /// <param name="orderStatus">Optional filter: Pending, Processing, Shipped, Delivered, Cancelled</param>
    /// <param name="page">Page number (default 1)</param>
    /// <param name="pageSize">Items per page (default 20)</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<SellerOrderListDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetOrders(
        [FromQuery] string? orderStatus = null,
        [FromQuery] int     page        = 1,
        [FromQuery] int     pageSize    = 20)
    {
        var sellerId = GetSellerId();
        var result   = await svc.GetOrdersAsync(sellerId, orderStatus, page, pageSize);
        return Ok(ApiResponse<PagedResult<SellerOrderListDto>>.Ok(result));
    }

    /// <summary>Get full order detail with items and address.</summary>
    /// <param name="orderId">Order ID</param>
    [HttpGet("{orderId:int}")]
    [ProducesResponseType(typeof(ApiResponse<SellerOrderDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOrderDetail(int orderId)
    {
        var sellerId = GetSellerId();
        var order    = await svc.GetOrderDetailAsync(sellerId, orderId);
        if (order is null)
            return NotFound(ApiResponse<object>.Fail("Order not found or unauthorized access."));

        return Ok(ApiResponse<SellerOrderDetailDto>.Ok(order));
    }

    /// <summary>Update the fulfilment status of a specific order item.</summary>
    /// <param name="id">Order item ID</param>
    /// <param name="req">New status value (e.g. Processing, Shipped, Delivered)</param>
    [HttpPatch("{id:int}/status")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateOrderStatus(int id, [FromBody] UpdateOrderStatusRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.OrderStatus))
            return BadRequest(ApiResponse<object>.Fail("Order status is required."));

        try
        {
            await svc.UpdateOrderStatusAsync(id, GetSellerId(), req.OrderStatus);
            return Ok(ApiResponse<object>.Ok(null!, "Order status updated successfully."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Update the status of an entire order. Only forward progression is allowed (1→2→3→4→5).</summary>
    /// <param name="orderId">Order ID</param>
    /// <param name="req">New status (1=Pending, 2=Confirmed, 3=Processing, 4=Shipped, 5=Delivered, 6=Cancelled)</param>
    [HttpPatch("update/{orderId:int}/status")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdateOrderStatusNew(int orderId, [FromBody] UpdateOrderStatusByNumRequest req)
    {
        try
        {
            var sellerId = GetSellerId();
            var result = await svc.UpdateOrderStatusNewAsync(orderId, sellerId, req.NewStatus);
            if (result is null)
                return NotFound(ApiResponse<object>.Fail("Order not found."));

            return Ok(ApiResponse<object>.Ok(result, "Order status updated successfully."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Cancel an order (only Pending/Confirmed/Processing orders can be cancelled).</summary>
    /// <param name="orderId">Order ID to cancel</param>
    /// <param name="req">Optional cancellation reason</param>
    [HttpPost("{orderId:int}/cancel")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CancelOrder(int orderId, [FromBody] SellerCancelOrderRequest req)
    {
        var sellerId = GetSellerId();
        var result   = await svc.CancelOrderAsync(orderId, sellerId, req.CancellationReason);

        // Fire-and-forget cancellation email. Wrap in Task.Run so SMTP latency
        // never blocks the seller's UX, but LOG any failure so a silent SMTP /
        // null-profile issue doesn't disappear forever (issue: buyer not emailed
        // on seller cancel — was previously caught and swallowed without trace).
        _ = Task.Run(async () =>
        {
            try
            {
                var profile = await authService.GetProfileAsync(result.BuyerUserId);
                var email   = profile?.Email;
                var name    = profile?.FirstName ?? "Customer";

                if (string.IsNullOrWhiteSpace(email))
                {
                    logger.LogWarning(
                        "Skipping cancellation email for order {OrderId}: buyer {BuyerUserId} has no email on file.",
                        orderId, result.BuyerUserId);
                    return;
                }

                await emailService.SendOrderCancellationAsync(
                    email, name, orderId, result.OrderNumber, result.TotalAmount, result.PaymentMode == 2);

                logger.LogInformation(
                    "Sent cancellation email for order {OrderId} ({OrderNumber}) to {Email}.",
                    orderId, result.OrderNumber, email);
            }
            catch (Exception ex)
            {
                logger.LogError(ex,
                    "Failed to send cancellation email for order {OrderId} to buyer {BuyerUserId}.",
                    orderId, result.BuyerUserId);
            }
        });

        return Ok(ApiResponse<object>.Ok(new { }, "Order cancelled successfully."));
    }

    private int GetSellerId() =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
