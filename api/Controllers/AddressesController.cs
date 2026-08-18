using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Addresses — manage delivery addresses. All endpoints require authentication.</summary>
[ApiController]
[Route("api/addresses")]
[Authorize]
[Produces("application/json")]
public class AddressesController(IAddressService addressService) : ControllerBase
{
    private int CurrentUserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>Returns all saved delivery addresses for the authenticated user.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<AddressDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> GetAddresses()
    {
        var addresses = await addressService.GetAddressesAsync(CurrentUserId);
        return Ok(ApiResponse<List<AddressDto>>.Ok(addresses));
    }

    /// <summary>Adds a new delivery address and returns its new ID.</summary>
    /// <param name="req">Address details: name, mobile, line1, line2, city, state, pincode, isDefault.</param>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> AddAddress([FromBody] AddAddressRequest req)
    {
        var id = await addressService.AddAddressAsync(CurrentUserId, req);
        return Ok(ApiResponse<object>.Ok(new { id }, "Address added."));
    }

    /// <summary>Sets the specified address as the default delivery address.</summary>
    /// <param name="id">Address ID to make default.</param>
    [HttpPut("{id:int}/default")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> SetDefault(int id)
    {
        await addressService.SetDefaultAddressAsync(id, CurrentUserId);
        return Ok(ApiResponse<object>.Ok(null!, "Default address updated."));
    }
}
