using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Product reviews — read and write customer reviews.</summary>
[ApiController]
[Route("api/products/{productId:int}/reviews")]
[Produces("application/json")]
public class ReviewsController(IEngagementService engagementService) : ControllerBase
{
    /// <summary>
    /// Returns paginated reviews for a product.
    /// Optional ?rating=1-5 filter. Optional ?page and ?pageSize.
    /// </summary>
    [HttpGet]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<ProductReviewsDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetReviews(
        int productId,
        [FromQuery] int? rating   = null,
        [FromQuery] int  page     = 1,
        [FromQuery] int  pageSize = 10)
    {
        var result = await engagementService.GetProductReviewsAsync(productId, rating, page, pageSize);
        return Ok(ApiResponse<ProductReviewsDto>.Ok(result));
    }

    /// <summary>
    /// Submits a review for a product. Requires rating 1–5 and a non-empty comment.
    /// Reviews are held for moderation before appearing publicly.
    /// AllowAnonymous temporarily for testing (UserId = 0 when unauthenticated).
    /// </summary>
    [HttpPost]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> AddReview(int productId, [FromBody] AddReviewRequest req)
    {
        if (req.Rating < 1 || req.Rating > 5)
            return BadRequest(ApiResponse<object>.Fail("Rating must be between 1 and 5."));
        if (string.IsNullOrWhiteSpace(req.Comment))
            return BadRequest(ApiResponse<object>.Fail("Review comment is required."));

        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var userId = int.TryParse(userIdClaim, out var uid) ? uid : 0;

        try
        {
            await engagementService.AddReviewAsync(productId, userId, req);
        }
        catch (SqlException ex) when (ex.Number == 50150 || ex.Number == 50151)
        {
            return BadRequest(ApiResponse<object>.Fail(ex.Message));
        }

        return Ok(ApiResponse<object>.Ok(new { }, "Review posted successfully."));
    }
}
