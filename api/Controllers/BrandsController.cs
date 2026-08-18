using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Brands — list of all active brands for filtering and browsing.</summary>
[ApiController]
[Route("api/brands")]
[Produces("application/json")]
public class BrandsController(IBrandService brandService) : ControllerBase
{
    /// <summary>Get all active brands for product filtering.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<BrandDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll()
    {
        var result = await brandService.GetAllAsync();
        return Ok(ApiResponse<List<BrandDto>>.Ok(result));
    }
}
