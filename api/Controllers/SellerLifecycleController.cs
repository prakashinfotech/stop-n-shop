using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>
/// Seller lifecycle endpoints — onboarding wizard, bank accounts, warehouses,
/// vendor agreement, settlements (T+7), and rolling performance score.
/// </summary>
[ApiController]
[Route("api/seller")]
[Produces("application/json")]
[Authorize(Roles = "Seller,Admin")]
public class SellerLifecycleController(ISellerLifecycleService svc) : ControllerBase
{
    [HttpPost("onboarding/stage")]
    public async Task<IActionResult> AdvanceStage([FromBody] AdvanceOnboardingRequest req)
    {
        var result = await svc.AdvanceStageAsync(GetSellerId(), req.Stage, GetUserId());
        return Ok(ApiResponse<OnboardingStageDto?>.Ok(result));
    }

    [HttpPost("documents")]
    public async Task<IActionResult> UploadDocument([FromBody] UploadSellerDocumentRequest req)
    {
        var result = await svc.UploadDocumentAsync(GetSellerId(), req, GetUserId());
        return Ok(ApiResponse<SellerDocumentDto?>.Ok(result));
    }

    [HttpPut("documents/{documentId:int}/verify")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> VerifyDocument(int documentId, [FromQuery] bool verified = true)
    {
        var result = await svc.VerifyDocumentAsync(documentId, GetUserId(), verified);
        return Ok(ApiResponse<SellerDocumentDto?>.Ok(result));
    }

    [HttpGet("bank-accounts")]
    public async Task<IActionResult> ListBankAccounts() =>
        Ok(ApiResponse<IEnumerable<SellerBankAccountDto>>.Ok(await svc.GetBankAccountsAsync(GetSellerId())));

    [HttpPost("bank-accounts")]
    public async Task<IActionResult> AddBankAccount([FromBody] AddSellerBankAccountRequest req)
    {
        var result = await svc.AddBankAccountAsync(GetSellerId(), req, GetUserId());
        return Ok(ApiResponse<SellerBankAccountDto?>.Ok(result));
    }

    [HttpPut("bank-accounts/{bankAccountId:int}/primary")]
    public async Task<IActionResult> SetPrimaryBankAccount(int bankAccountId)
    {
        var ok = await svc.SetPrimaryBankAccountAsync(bankAccountId, GetSellerId(), GetUserId());
        return ok
            ? Ok(ApiResponse<object>.Ok(null!, "Primary bank account updated."))
            : NotFound(ApiResponse<object>.Fail("Bank account not found."));
    }

    [HttpGet("warehouses")]
    public async Task<IActionResult> ListWarehouses() =>
        Ok(ApiResponse<IEnumerable<SellerWarehouseDto>>.Ok(await svc.GetWarehousesAsync(GetSellerId())));

    [HttpPost("warehouses")]
    public async Task<IActionResult> UpsertWarehouse([FromBody] UpsertSellerWarehouseRequest req)
    {
        var result = await svc.UpsertWarehouseAsync(GetSellerId(), req, GetUserId());
        return Ok(ApiResponse<SellerWarehouseDto?>.Ok(result));
    }

    [HttpPost("agreement/accept")]
    public async Task<IActionResult> AcceptAgreement([FromBody] AcceptVendorAgreementRequest req)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var ua = Request.Headers.UserAgent.ToString();
        var result = await svc.AcceptAgreementAsync(GetSellerId(), req, ip, ua, GetUserId());
        return Ok(ApiResponse<VendorAgreementDto?>.Ok(result));
    }

    [HttpGet("agreement/latest")]
    public async Task<IActionResult> GetLatestAgreement() =>
        Ok(ApiResponse<VendorAgreementDto?>.Ok(await svc.GetLatestAgreementAsync(GetSellerId())));

    [HttpGet("settlements")]
    public async Task<IActionResult> ListSettlements([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var (items, total) = await svc.ListSettlementsAsync(GetSellerId(), page, pageSize);
        return Ok(ApiResponse<object>.Ok(new { items, totalCount = total, page, pageSize }));
    }

    [HttpGet("settlements/{settlementId:int}")]
    public async Task<IActionResult> GetSettlement(int settlementId)
    {
        var result = await svc.GetSettlementAsync(settlementId, GetSellerId());
        return result.Settlement is null
            ? NotFound(ApiResponse<object>.Fail("Settlement not found."))
            : Ok(ApiResponse<SellerSettlementDetailDto>.Ok(result));
    }

    [HttpPost("settlements/calculate")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> CalculateSettlement([FromQuery] int sellerId, [FromBody] CalculateSettlementRequest req)
    {
        var result = await svc.CalculateSettlementAsync(sellerId, req.PeriodStart, req.PeriodEnd, GetUserId());
        return Ok(ApiResponse<SellerSettlementDto?>.Ok(result));
    }

    [HttpGet("performance-score")]
    public async Task<IActionResult> GetPerformanceScore() =>
        Ok(ApiResponse<SellerPerformanceScoreDto?>.Ok(await svc.GetLatestScoreAsync(GetSellerId())));

    [HttpPost("performance-score/recompute")]
    public async Task<IActionResult> RecomputeScore() =>
        Ok(ApiResponse<SellerPerformanceScoreDto?>.Ok(await svc.RecomputeScoreAsync(GetSellerId())));

    private int GetSellerId() => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private int GetUserId()   => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
