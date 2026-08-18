using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Wishlist — get and toggle saved products. All endpoints require authentication.</summary>
[ApiController]
[Route("api/wishlist")]
[Authorize]
[Produces("application/json")]
public class WishlistController(IWishlistService wishlistService) : ControllerBase
{
    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>Returns all products saved in the authenticated user's wishlist.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<WishlistItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetWishlist()
    {
        var items = await wishlistService.GetWishlistAsync(CurrentUserId);
        return Ok(ApiResponse<List<WishlistItemDto>>.Ok(items));
    }

    /// <summary>
    /// Toggles a product in/out of the wishlist.
    /// Returns isWishlisted = true when added, false when removed.
    /// </summary>
    /// <param name="productId">Product ID to toggle.</param>
    [HttpPost("{productId:int}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Toggle(int productId)
    {
        var isWishlisted = await wishlistService.ToggleWishlistAsync(CurrentUserId, productId);
        var msg = isWishlisted ? "Added to wishlist." : "Removed from wishlist.";
        return Ok(ApiResponse<object>.Ok(new { isWishlisted }, msg));
    }
}
