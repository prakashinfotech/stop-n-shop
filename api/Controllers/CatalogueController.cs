using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Catalogue — mega menu, banners, stores, pincode delivery check.</summary>
[ApiController]
[Route("api")]
[Produces("application/json")]
public class CatalogueController(ICatalogueService catalogueService) : ControllerBase
{
    /// <summary>Returns the full mega-menu tree: categories → sub-categories → product types.</summary>
    [HttpGet("menu")]
    [ProducesResponseType(typeof(ApiResponse<List<MegaMenuCategoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMegaMenu()
    {
        var menu = await catalogueService.GetMegaMenuAsync();
        return Ok(ApiResponse<List<MegaMenuCategoryDto>>.Ok(menu));
    }

    /// <summary>Admin-curated trending subcategories for the home page tile grid.</summary>
    [HttpGet("subcategories/featured")]
    [ProducesResponseType(typeof(ApiResponse<List<FeaturedSubCategoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetFeaturedSubCategories([FromQuery] int count = 10)
    {
        var items = await catalogueService.GetFeaturedSubCategoriesAsync(count);
        return Ok(ApiResponse<List<FeaturedSubCategoryDto>>.Ok(items));
    }

    /// <summary>Returns banners for the specified section.</summary>
    /// <param name="section">Banner section (1–7, default: 1).</param>
    [HttpGet("banners")]
    [ProducesResponseType(typeof(ApiResponse<List<BannerDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBanners([FromQuery] int section = 1)
    {
        var banners = await catalogueService.GetBannersAsync(section);
        return Ok(ApiResponse<List<BannerDto>>.Ok(banners));
    }

    /// <summary>Returns every active promotional banner (BannerType 2..7) in one ordered list.</summary>
    [HttpGet("banners/stack")]
    [ProducesResponseType(typeof(ApiResponse<List<BannerDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetBannerStack()
    {
        var banners = await catalogueService.GetBannerStackAsync();
        return Ok(ApiResponse<List<BannerDto>>.Ok(banners));
    }

    /// <summary>Returns store locations, optionally filtered by city.</summary>
    /// <param name="city">City name filter (optional).</param>
    [HttpGet("stores")]
    [ProducesResponseType(typeof(ApiResponse<List<StoreDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetStores([FromQuery] string? city)
    {
        var stores = await catalogueService.GetStoresAsync(city);
        return Ok(ApiResponse<List<StoreDto>>.Ok(stores));
    }

    /// <summary>Checks whether delivery is available for the given 6-digit pincode.</summary>
    /// <param name="pin">6-digit numeric pincode.</param>
    [HttpGet("pincode/{pin}")]
    [ProducesResponseType(typeof(ApiResponse<PincodeDeliveryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> GetPincodeDelivery(string pin)
    {
        if (pin.Length != 6 || !pin.All(char.IsDigit))
            return BadRequest(ApiResponse<object>.Fail("Invalid pincode."));

        var result = await catalogueService.GetPincodeDeliveryAsync(pin);
        if (result is null)
            return Ok(ApiResponse<PincodeDeliveryDto>.Ok(
                new PincodeDeliveryDto { Pincode = pin, IsDeliverable = false },
                "Delivery not available for this pincode."));

        return Ok(ApiResponse<PincodeDeliveryDto>.Ok(result));
    }

    /// <summary>Returns a list of all product categories.</summary>
    [HttpGet("categories")]
    [ProducesResponseType(typeof(ApiResponse<List<CategoryDropdownDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetCategories()
    {
        var categories = await catalogueService.GetCategoriesAsync();
        return Ok(ApiResponse<List<CategoryDropdownDto>>.Ok(categories));
    }

    /// <summary>Returns a list of subcategories for a given category.</summary>
    /// <param name="categoryId">Category ID</param>
    [HttpGet("categories/{categoryId:int}/subcategories")]
    [ProducesResponseType(typeof(ApiResponse<List<SubCategoryDropdownDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSubCategories(int categoryId)
    {
        var subCategories = await catalogueService.GetSubCategoriesByCategoryAsync(categoryId);
        return Ok(ApiResponse<List<SubCategoryDropdownDto>>.Ok(subCategories));
    }

    /// <summary>
    /// Returns the per-subcategory product-form schema that drives the seller
    /// add/edit wizard rendering (image angles, size scale, gender + dimensions flags).
    /// </summary>
    [HttpGet("catalog/subcategories/{subCategoryId:int}/form-schema")]
    [ResponseCache(Duration = 300, Location = ResponseCacheLocation.Any)]
    [ProducesResponseType(typeof(ApiResponse<SubCategoryFormSchemaDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSubCategoryFormSchema(int subCategoryId)
    {
        var schema = await catalogueService.GetSubCategoryFormSchemaAsync(subCategoryId);
        if (schema is null) return NotFound(ApiResponse<object>.Fail("Subcategory not found."));
        return Ok(ApiResponse<SubCategoryFormSchemaDto>.Ok(schema));
    }
}
