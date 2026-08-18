using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>
/// Dispatcher / delivery-agent portal endpoints. All gated on Role=Dispatcher.
/// SellerId equivalent for dispatchers is resolved via UserId → DispatcherId
/// inside each request (defensive — the JWT only carries UserId + Role).
/// </summary>
[ApiController]
[Route("api/dispatcher")]
[Authorize(Roles = "Dispatcher")]
[Produces("application/json")]
public class DispatcherController(IDispatcherService svc) : ControllerBase
{
    private int CurrentUserId =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static IActionResult Paged<T>(List<T> items, int total, int page, int pageSize)
        => new OkObjectResult(ApiResponse<object>.Ok(new
        {
            items,
            totalCount = total,
            pageNo     = page,
            pageSize,
        }));

    private async Task<int?> ResolveDispatcherIdAsync()
    {
        var profile = await svc.GetProfileByUserIdAsync(CurrentUserId);
        return profile?.DispatcherId;
    }

    /// <summary>Current dispatcher's profile (warehouses assigned, vehicle, etc).</summary>
    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile()
    {
        var profile = await svc.GetProfileByUserIdAsync(CurrentUserId);
        if (profile is null)
            return NotFound(ApiResponse<object>.Fail("No dispatcher profile linked to this account."));
        return Ok(ApiResponse<DispatcherProfileDto>.Ok(profile));
    }

    /// <summary>Pickup queue — Packed items at the dispatcher's assigned
    /// warehouses, plus items they've already claimed (status 10).</summary>
    [HttpGet("pickups")]
    public async Task<IActionResult> GetPickupQueue([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var dispatcherId = await ResolveDispatcherIdAsync();
        if (dispatcherId is null)
            return Unauthorized(ApiResponse<object>.Fail("No dispatcher profile found."));

        var (items, total) = await svc.GetPickupQueueAsync(dispatcherId.Value, page, pageSize);
        return Paged(items, total, page, pageSize);
    }

    /// <summary>Claim a packed item — moves status 3 → 10 and reserves it for
    /// this dispatcher. SP enforces warehouse-assignment ownership.</summary>
    [HttpPost("pickups/{orderItemId:int}/claim")]
    public async Task<IActionResult> ClaimPickup(int orderItemId)
    {
        var dispatcherId = await ResolveDispatcherIdAsync();
        if (dispatcherId is null)
            return Unauthorized(ApiResponse<object>.Fail("No dispatcher profile found."));

        try
        {
            var result = await svc.ClaimPickupAsync(orderItemId, dispatcherId.Value);
            return Ok(ApiResponse<DispatcherClaimResultDto>.Ok(result, "Pickup claimed."));
        }
        catch (SqlException ex) when (ex.Number is 50410 or 50411 or 50412)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>"Leaving warehouse" — bulk transitions every status-10 item
    /// claimed by this dispatcher into status 4 (Dispatched). Idempotent
    /// (returns 0 if nothing to confirm).</summary>
    [HttpPost("pickups/confirm")]
    public async Task<IActionResult> ConfirmPickup()
    {
        var dispatcherId = await ResolveDispatcherIdAsync();
        if (dispatcherId is null)
            return Unauthorized(ApiResponse<object>.Fail("No dispatcher profile found."));

        var count = await svc.ConfirmPickupAsync(dispatcherId.Value);
        var msg = count == 0
            ? "No picked-up items to confirm."
            : $"{count} item{(count == 1 ? string.Empty : "s")} dispatched.";
        return Ok(ApiResponse<object>.Ok(new { confirmed = count }, msg));
    }

    /// <summary>Mark a Dispatched parcel (status 4) as Out for Delivery (status 9).
    /// This unlocks the delivery-OTP flow for the item.</summary>
    [HttpPost("deliveries/{assignmentId:int}/out-for-delivery")]
    public async Task<IActionResult> MarkOutForDelivery(int assignmentId)
    {
        var dispatcherId = await ResolveDispatcherIdAsync();
        if (dispatcherId is null)
            return Unauthorized(ApiResponse<object>.Fail("No dispatcher profile found."));

        try
        {
            var result = await svc.MarkOutForDeliveryAsync(assignmentId, dispatcherId.Value);
            return Ok(ApiResponse<DispatcherClaimResultDto>.Ok(result, "Marked out for delivery."));
        }
        catch (SqlException ex) when (ex.Number is 50420 or 50421)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Generate + send a delivery OTP to the buyer (in-app always,
    /// SMS best-effort). The OTP itself is never returned in the response.</summary>
    [HttpPost("deliveries/{assignmentId:int}/send-otp")]
    public async Task<IActionResult> SendDeliveryOtp(int assignmentId)
    {
        var dispatcherId = await ResolveDispatcherIdAsync();
        if (dispatcherId is null)
            return Unauthorized(ApiResponse<object>.Fail("No dispatcher profile found."));

        try
        {
            var (orderNumber, smsSent) = await svc.SendDeliveryOtpAsync(assignmentId, dispatcherId.Value);
            var msg = smsSent
                ? "OTP sent to the buyer via SMS + app."
                : "OTP sent to the buyer in-app. (SMS unavailable — buyer can read it from their notifications.)";
            return Ok(ApiResponse<object>.Ok(new { orderNumber, smsSent }, msg));
        }
        catch (SqlException ex) when (ex.Number is 50430 or 50431)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>Verify the buyer's OTP and complete the delivery (proof + COD).
    /// 3 wrong attempts → 5-minute lockout.</summary>
    [HttpPost("deliveries/{assignmentId:int}/complete")]
    public async Task<IActionResult> CompleteDelivery(int assignmentId, [FromBody] DispatcherCompleteDeliveryRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Otp) || req.Otp.Trim().Length != 6)
            return BadRequest(ApiResponse<object>.Fail("Enter the 6-digit OTP."));

        var dispatcherId = await ResolveDispatcherIdAsync();
        if (dispatcherId is null)
            return Unauthorized(ApiResponse<object>.Fail("No dispatcher profile found."));

        try
        {
            var result = await svc.VerifyDeliveryOtpAsync(assignmentId, dispatcherId.Value, req);
            return Ok(ApiResponse<DispatcherClaimResultDto>.Ok(result, "Delivered. Buyer's order is complete."));
        }
        catch (SqlException ex) when (ex.Number is >= 50432 and <= 50437)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }
    }

    /// <summary>All active assignments (status 10 / 4 / 9 / 11) for this dispatcher.</summary>
    [HttpGet("assignments/active")]
    public async Task<IActionResult> GetActive([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var dispatcherId = await ResolveDispatcherIdAsync();
        if (dispatcherId is null)
            return Unauthorized(ApiResponse<object>.Fail("No dispatcher profile found."));

        var (items, total) = await svc.GetActiveAsync(dispatcherId.Value, page, pageSize);
        return Paged(items, total, page, pageSize);
    }
}
