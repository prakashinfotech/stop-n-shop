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
/// Warehouse-aware stock operations. Admin endpoints see every seller's stock;
/// seller endpoints are scoped to the calling seller.
/// </summary>
[ApiController]
[Route("api/inventory")]
[Produces("application/json")]
public class InventoryController(IInventoryService svc) : ControllerBase
{
    private int  CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private string? ClientIp   => HttpContext?.Connection.RemoteIpAddress?.ToString();

    /// <summary>
    /// Resolves the seller scope for a read query. Sellers are force-scoped to
    /// their own SellerId (NameIdentifier == SellerId in seller-issued JWTs —
    /// see <c>SellerAuthService</c>). Admins may pass <paramref name="requested"/>
    /// to scope to a specific seller, or leave it null for cross-seller view.
    /// </summary>
    private int? ResolveSellerScope(int? requested)
        => User.IsInRole("Seller") ? CurrentUserId : requested;

    private static IActionResult Paged<T>(List<T> items, int total, int page, int pageSize)
        => new OkObjectResult(ApiResponse<object>.Ok(new
        {
            items,
            totalCount = total,
            pageNo     = page,
            pageSize,
        }));

    // ── Reads (Admin OR Seller) ──────────────────────────────────────────────

    /// <summary>List warehouses. Admin sees all; sellers see their own + platform warehouses.</summary>
    [HttpGet("warehouses")]
    [Authorize(Roles = "Admin,Seller")]
    public async Task<IActionResult> GetWarehouses([FromQuery] int? sellerId = null, [FromQuery] bool includeInactive = false)
    {
        var items = await svc.GetWarehousesAsync(ResolveSellerScope(sellerId), includeInactive);
        return Ok(ApiResponse<List<WarehouseDto>>.Ok(items));
    }

    /// <summary>Per-variant stock across all warehouses.</summary>
    [HttpGet("variants/{variantId:int}/stock")]
    [Authorize(Roles = "Admin,Seller")]
    public async Task<IActionResult> GetStockByVariant(int variantId)
    {
        var items = await svc.GetStockByVariantAsync(variantId);
        return Ok(ApiResponse<List<StockRowDto>>.Ok(items));
    }

    /// <summary>SKU × Warehouse matrix. Admin: cross-seller; Seller: forced to own SellerId.</summary>
    [HttpGet("matrix")]
    [Authorize(Roles = "Admin,Seller")]
    public async Task<IActionResult> GetMatrix(
        [FromQuery] int? sellerId    = null,
        [FromQuery] int? warehouseId = null,
        [FromQuery] string? search   = null,
        [FromQuery] int pageNo       = 1,
        [FromQuery] int pageSize     = 50)
    {
        var (items, total) = await svc.GetStockMatrixAsync(ResolveSellerScope(sellerId), warehouseId, search, pageNo, pageSize);
        return Paged(items, total, pageNo, pageSize);
    }

    /// <summary>Low-stock alert feed. Admin: cross-seller (pass <c>sellerId</c> to scope); Seller: forced to own SellerId.</summary>
    [HttpGet("low-stock")]
    [Authorize(Roles = "Admin,Seller")]
    public async Task<IActionResult> GetLowStock(
        [FromQuery] int? sellerId    = null,
        [FromQuery] int? warehouseId = null,
        [FromQuery] int pageNo       = 1,
        [FromQuery] int pageSize     = 50)
    {
        var (items, total) = await svc.GetLowStockAlertsAsync(ResolveSellerScope(sellerId), warehouseId, pageNo, pageSize);
        return Paged(items, total, pageNo, pageSize);
    }

    /// <summary>Movement ledger for a variant (admin drawer view).</summary>
    [HttpGet("variants/{variantId:int}/movements")]
    [Authorize(Roles = "Admin,Seller")]
    public async Task<IActionResult> GetMovements(
        int variantId,
        [FromQuery] int? warehouseId = null,
        [FromQuery] int pageNo       = 1,
        [FromQuery] int pageSize     = 50)
    {
        var (items, total) = await svc.GetMovementsByVariantAsync(variantId, warehouseId, pageNo, pageSize);
        return Paged(items, total, pageNo, pageSize);
    }

    // ── Writes (Admin) ───────────────────────────────────────────────────────

    /// <summary>Adjust stock for a variant at a warehouse. Signed delta; emits a StockMovement row.</summary>
    [HttpPost("stock/adjust")]
    [Authorize(Roles = "Admin,Seller")]
    public async Task<IActionResult> Adjust([FromBody] StockAdjustRequest req)
    {
        try
        {
            var (onHand, reserved) = await svc.AdjustStockAsync(req, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(new { onHand, reserved }, "Stock adjusted."));
        }
        catch (ValidationException ex)                        { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
        catch (SqlException ex) when (ex.Number is >= 50300 and <= 50304) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    /// <summary>Place a TTL'd hold on stock. Used by checkout flows.</summary>
    [HttpPost("stock/reserve")]
    [Authorize(Roles = "Admin,Seller,Buyer")]
    public async Task<IActionResult> Reserve([FromBody] StockReserveRequest req)
    {
        try
        {
            var res = await svc.ReserveAsync(req, userId: CurrentUserId, changedBy: CurrentUserId, ClientIp);
            return Ok(ApiResponse<StockReserveResult>.Ok(res, "Reservation created."));
        }
        catch (ValidationException ex)                        { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
        catch (SqlException ex) when (ex.Number is >= 50310 and <= 50313) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    /// <summary>Release a reservation, or commit it (with <c>commitToOrderId</c>) into an order.</summary>
    [HttpPost("stock/release")]
    [Authorize(Roles = "Admin,Seller,Buyer")]
    public async Task<IActionResult> Release([FromBody] StockReleaseRequest req)
    {
        try
        {
            await svc.ReleaseAsync(req, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(null!, req.CommitToOrderId.HasValue ? "Reservation committed." : "Reservation released."));
        }
        catch (SqlException ex) when (ex.Number == 50320)     { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
    }

    /// <summary>Move stock between warehouses (step 1 of 2).</summary>
    [HttpPost("transfers")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> InitiateTransfer([FromBody] StockTransferInitiateRequest req)
    {
        try
        {
            var id = await svc.InitiateTransferAsync(req, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(new { transferId = id }, "Transfer initiated."));
        }
        catch (ValidationException ex)                        { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
        catch (SqlException ex) when (ex.Number is >= 50330 and <= 50333) { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }

    /// <summary>Mark a transfer as received at the destination warehouse (step 2 of 2).</summary>
    [HttpPatch("transfers/{id:int}/receive")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ReceiveTransfer(int id)
    {
        try
        {
            await svc.ReceiveTransferAsync(id, CurrentUserId, ClientIp);
            return Ok(ApiResponse<object>.Ok(null!, "Transfer received."));
        }
        catch (SqlException ex) when (ex.Number == 50340)     { return NotFound(ApiResponse<object>.Fail(ex.Message)); }
        catch (SqlException ex) when (ex.Number == 50341)     { return BadRequest(ApiResponse<object>.Fail(ex.Message)); }
    }
}
