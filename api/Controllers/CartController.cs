using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Cart — view, add, update, and remove cart items. All endpoints require authentication.</summary>
[ApiController]
[Route("api/cart")]
[Authorize]
[Produces("application/json")]
public class CartController(ICartService cartService) : ControllerBase
{
    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>Returns the authenticated user's cart with items and order summary.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<CartDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetCart()
    {
        var cart = await cartService.GetCartAsync(CurrentUserId);
        return Ok(ApiResponse<CartDto>.Ok(cart));
    }

    /// <summary>Adds a product to the cart. If the same product+size+color already exists, increments quantity.</summary>
    /// <param name="req">Product ID, optional size label, optional color name, quantity (default 1).</param>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> AddToCart([FromBody] AddToCartRequest req)
    {
        var cartId = await cartService.AddToCartAsync(CurrentUserId, req);
        return Ok(ApiResponse<object>.Ok(new { cartId }, "Added to cart."));
    }

    /// <summary>Updates the quantity of a specific cart line item.</summary>
    /// <param name="cartId">Cart item ID (the id field on each cart item).</param>
    /// <param name="req">New quantity.</param>
    [HttpPut("{cartId:int}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> UpdateCart(int cartId, [FromBody] UpdateCartRequest req)
    {
        var result = await cartService.UpdateCartAsync(cartId, CurrentUserId, req.Quantity);
        return Ok(ApiResponse<object>.Ok(new { updated = result }, "Cart updated."));
    }

    /// <summary>Removes a specific cart line item.</summary>
    /// <param name="cartId">Cart item ID to remove.</param>
    [HttpDelete("{cartId:int}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> DeleteCartItem(int cartId)
    {
        await cartService.DeleteCartItemAsync(cartId, CurrentUserId);
        return Ok(ApiResponse<object>.Ok(null!, "Item removed."));
    }
}
