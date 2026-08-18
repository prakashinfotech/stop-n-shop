using Microsoft.AspNetCore.Mvc;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Products — listing, detail, similar products, and personalised recommendations.</summary>
[ApiController]
[Route("api/products")]
[Produces("application/json")]
public class ProductsController(IProductService productService) : ControllerBase
{
    /// <summary>
    /// Returns a paginated, filtered, and sorted product list.
    /// All query parameters are optional.
    /// </summary>
    /// <param name="query">
    /// Filters: categoryId, subCategoryId, brandIds (CSV), gender, sizes (CSV), colors (CSV),
    /// minPrice, maxPrice, minDiscount, search.
    /// Sorting: sortBy = POPULAR | LATEST | DISCOUNT | PRICE_ASC | PRICE_DESC (default POPULAR).
    /// Pagination: pageNo (default 1), pageSize (default 20).
    /// </param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<ProductListItemDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProducts([FromQuery] ProductQueryParams query)
    {
        var result = await productService.GetProductsAsync(query);
        return Ok(ApiResponse<PagedResult<ProductListItemDto>>.Ok(result));
    }

    /// <summary>Returns full product detail including images, sizes, colors, and applicable offers.</summary>
    /// <param name="id">Product ID.</param>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<ProductDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProduct(int id)
    {
        var product = await productService.GetProductDetailAsync(id);
        if (product is null) return NotFound(ApiResponse<object>.Fail("Product not found."));
        return Ok(ApiResponse<ProductDetailDto>.Ok(product));
    }

    /// <summary>
    /// Returns master site-wide offers shown on every product detail page:
    /// the storefront coupons and the informational bank/card payment offers.
    /// Cached aggressively on the client — the same payload applies to every product.
    /// </summary>
    [HttpGet("offers/master")]
    [ProducesResponseType(typeof(ApiResponse<OffersMasterDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMasterOffers()
    {
        var offers = await productService.GetOffersMasterAsync();
        return Ok(ApiResponse<OffersMasterDto>.Ok(offers));
    }

    /// <summary>Returns up to 10 products similar to the given product (same sub-category).</summary>
    /// <param name="id">Product ID.</param>
    [HttpGet("{id:int}/similar")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductListItemDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetSimilar(int id)
    {
        var items = await productService.GetSimilarProductsAsync(id);
        return Ok(ApiResponse<List<ProductListItemDto>>.Ok(items));
    }

    /// <summary>Returns recommended products for the given product IDs (used on the product detail page).</summary>
    /// <param name="productIds">Comma-separated product IDs, e.g. "1,2,3".</param>
    [HttpGet("recommended")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductListItemDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRecommended([FromQuery] string productIds = "")
    {
        var items = await productService.GetRecommendedProductsAsync(productIds);
        return Ok(ApiResponse<List<ProductListItemDto>>.Ok(items));
    }

    /// <summary>Top products by rolling-window view count from ProductViewLogs.</summary>
    /// <param name="days">Window in days (default 7).</param>
    /// <param name="limit">Max products to return (default 12).</param>
    [HttpGet("trending")]
    [ProducesResponseType(typeof(ApiResponse<List<ProductListItemDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetTrending([FromQuery] int days = 7, [FromQuery] int limit = 12)
    {
        var items = await productService.GetTrendingProductsAsync(days, limit);
        return Ok(ApiResponse<List<ProductListItemDto>>.Ok(items));
    }
}
