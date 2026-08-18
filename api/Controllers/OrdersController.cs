using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Orders — place orders and view order history. All endpoints require authentication.</summary>
[ApiController]
[Route("api/orders")]
[Authorize]
[Produces("application/json")]
public class OrdersController(IOrderService orderService) : ControllerBase
{
    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// Places an order from the current cart contents.
    /// Deducts stock, clears the cart, and returns the new order ID.
    /// </summary>
    /// <param name="req">Delivery address ID and payment method (UPI | CARD | NETBANKING | COD).</param>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> PlaceOrder([FromBody] PlaceOrderRequest req)
    {
        var orderId = await orderService.PlaceOrderAsync(CurrentUserId, req);
        return Ok(ApiResponse<object>.Ok(new { orderId }, "Order placed successfully."));
    }

    /// <summary>Returns a summary list of all orders for the authenticated user, newest first.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<OrderListItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetOrders()
    {
        var orders = await orderService.GetOrdersAsync(CurrentUserId);
        return Ok(ApiResponse<List<OrderListItemDto>>.Ok(orders));
    }

    /// <summary>Returns full order detail including items, tracking timeline, and shipping address.</summary>
    /// <param name="id">Order ID.</param>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<OrderDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetOrder(int id)
    {
        var order = await orderService.GetOrderDetailAsync(id, CurrentUserId);
        if (order is null) return NotFound(ApiResponse<object>.Fail("Order not found."));
        return Ok(ApiResponse<OrderDetailDto>.Ok(order));
    }

    /// <summary>Cancels an order before seller accepts it. Only available for Pending orders.</summary>
    /// <param name="id">Order ID.</param>
    /// <param name="req">Cancellation reason.</param>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<OrderDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CancelOrder(int id, [FromBody] CancelOrderRequest req)
    {
        try
        {
            var order = await orderService.CancelOrderAsync(id, CurrentUserId, req.Reason);
            if (order is null) return NotFound(ApiResponse<object>.Fail("Order not found."));
            return Ok(ApiResponse<OrderDetailDto>.Ok(order, "Order cancelled successfully."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }
}
