using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>
/// Seller-side per-item fulfilment console: confirm or reject (with reason)
/// individual order lines that this seller owns.
/// </summary>
[ApiController]
[Route("api/seller/orders")]
[Authorize(Roles = "Seller")]
[Produces("application/json")]
public class SellerOrderFulfillmentController(
    ISellerOrderService svc,
    IValidator<SellerRejectItemRequest> rejectValidator)
    : ControllerBase
{
    private int GetSellerId() =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>Paged queue of order items for this seller, filtered by fulfilment state.</summary>
    [HttpGet("items")]
    public async Task<IActionResult> GetQueue(
        [FromQuery] string status   = "placed",
        [FromQuery] int    page     = 1,
        [FromQuery] int    pageSize = 20)
    {
        var allowed = new[] { "placed", "confirmed", "rejected", "fulfilled", "all" };
        var clean   = allowed.Contains(status?.ToLowerInvariant()) ? status!.ToLowerInvariant() : "placed";

        var (items, total) = await svc.GetQueueAsync(GetSellerId(), clean, page, pageSize);
        return Ok(ApiResponse<object>.Ok(new
        {
            items,
            totalCount = total,
            page,
            pageSize,
        }));
    }

    /// <summary>Per-tab counts (placed / confirmed / rejected / fulfilled / all) for this seller's queue.
    /// One round-trip; intended to be polled by the UI (~30s) to keep tab badges live.</summary>
    [HttpGet("items/counts")]
    public async Task<IActionResult> GetQueueCounts()
    {
        var counts = await svc.GetQueueCountsAsync(GetSellerId());
        return Ok(ApiResponse<SellerQueueCountsDto>.Ok(counts));
    }

    /// <summary>Confirm a single line. Only "Placed" items can be confirmed.</summary>
    [HttpPatch("items/{orderItemId:int}/confirm")]
    public async Task<IActionResult> Confirm(int orderItemId)
    {
        try
        {
            var result = await svc.ConfirmItemAsync(orderItemId, GetSellerId());
            return Ok(ApiResponse<SellerActionResultDto>.Ok(result, "Order item confirmed."));
        }
        catch (SqlException ex) when (ex.Number is 50300 or 50301) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    /// <summary>Reject a single line with a reason. Restocks the variant and refunds wallet if pre-paid.</summary>
    [HttpPatch("items/{orderItemId:int}/reject")]
    public async Task<IActionResult> Reject(int orderItemId, [FromBody] SellerRejectItemRequest req)
    {
        var v = await rejectValidator.ValidateAsync(req);
        if (!v.IsValid)
            return BadRequest(ApiResponse<object>.Fail(v.Errors[0].ErrorMessage));

        try
        {
            var result = await svc.RejectItemAsync(orderItemId, GetSellerId(), req.Reason);
            return Ok(ApiResponse<SellerActionResultDto>.Ok(result, "Order item rejected. Buyer has been notified."));
        }
        catch (SqlException ex) when (ex.Number is 50300 or 50302 or 50303)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Move a confirmed line one step forward in the fulfilment flow:
    /// Confirmed → Packed → Dispatched → Out for Delivery → Delivered.
    /// SP enforces forward-only one-step-at-a-time transitions.</summary>
    [HttpPatch("items/{orderItemId:int}/status")]
    public async Task<IActionResult> UpdateStatus(int orderItemId, [FromBody] SellerUpdateItemStatusRequest req)
    {
        try
        {
            var result = await svc.UpdateItemStatusAsync(orderItemId, GetSellerId(), req.NewStatus);
            return Ok(ApiResponse<SellerActionResultDto>.Ok(result, "Order item status updated."));
        }
        catch (SqlException ex) when (ex.Number is 50305 or 50306)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>
    /// Returns the print-ready data bundle for a confirmed (or further-along) order item.
    /// The UI renders the shipping sticker (A6) + invoice receipt (A4) from this payload.
    /// </summary>
    [HttpGet("items/{orderItemId:int}/label-data")]
    public async Task<IActionResult> GetLabelData(int orderItemId)
    {
        try
        {
            var data = await svc.GetLabelDataAsync(orderItemId, GetSellerId());
            return Ok(ApiResponse<SellerLabelDataDto>.Ok(data));
        }
        catch (SqlException ex) when (ex.Number is 50310 or 50311)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }
}
