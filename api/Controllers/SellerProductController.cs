using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Services;

namespace ShopNShop.Api.Controllers;

/// <summary>Seller product management — CRUD, image upload, inventory.</summary>
[ApiController]
[Route("api/seller/products")]
[Produces("application/json")]
[Authorize(Roles = "Seller")]
public class SellerProductController(ISellerProductService svc, IWebHostEnvironment env, IConfiguration config) : ControllerBase
{
    /// <summary>Returns a paginated list of the seller's products.</summary>
    /// <param name="approvalStatus">Optional filter: Pending, Approved, Rejected</param>
    /// <param name="page">Page number (default 1)</param>
    /// <param name="pageSize">Items per page (default 20)</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<SellerProductListDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetProducts(
        [FromQuery] string? approvalStatus = null,
        [FromQuery] int     page           = 1,
        [FromQuery] int     pageSize       = 20)
    {
        var result = await svc.GetProductsAsync(GetSellerId(), approvalStatus, page, pageSize);
        return Ok(ApiResponse<PagedResult<SellerProductListDto>>.Ok(result));
    }

    /// <summary>Returns full product detail including images, sizes, colors.</summary>
    /// <param name="id">Product ID</param>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<SellerProductDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetProduct(int id)
    {
        var product = await svc.GetDetailAsync(id, GetSellerId());
        if (product is null) return NotFound(ApiResponse<object>.Fail("Product not found."));
        return Ok(ApiResponse<SellerProductDetailDto>.Ok(product));
    }

    /// <summary>Create a new product. Returns the created product detail.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<SellerProductDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> CreateProduct([FromBody] CreateSellerProductRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Name)) return BadRequest(ApiResponse<object>.Fail("Product name is required."));
        if (req.CategoryId <= 0)                 return BadRequest(ApiResponse<object>.Fail("Please select a category."));
        if (req.MRP <= 0)                        return BadRequest(ApiResponse<object>.Fail("MRP must be greater than zero."));
        if (req.SellingPrice <= 0)               return BadRequest(ApiResponse<object>.Fail("Selling price must be greater than zero."));
        //if selling price is less than MRP show as discount
        //Discount applied on MRP
        var result = await svc.CreateAsync(GetSellerId(), req);
        return Ok(ApiResponse<SellerProductDetailDto>.Ok(result, "Product created successfully."));
    }

    /// <summary>Update an existing product. Only the owning seller can update.</summary>
    /// <param name="id">Product ID</param>
    /// <param name="req">Fields to update</param>
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateProduct(int id, [FromBody] UpdateSellerProductRequest req)
    {
        try
        {
            await svc.UpdateAsync(id, GetSellerId(), req);
            return Ok(ApiResponse<object>.Ok(null!, "Product updated successfully."));
        }
        catch (Microsoft.Data.SqlClient.SqlException ex) when (ex.Number == 50110)
        {
            // SP guard: seller doesn't own this product.
            return StatusCode(StatusCodes.Status403Forbidden,
                ApiResponse<object>.Fail("You don't own this product or it no longer exists."));
        }
    }

    /// <summary>Soft-delete a product (sets IsActive = false). Only the owning seller can delete.</summary>
    /// <param name="id">Product ID</param>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        await svc.DeleteAsync(id, GetSellerId());
        return Ok(ApiResponse<object>.Ok(null!, "Product deactivated successfully."));
    }

    /// <summary>Update stock quantity and low-stock threshold for a product.</summary>
    /// <param name="id">Product ID</param>
    /// <param name="req">Inventory fields to update</param>
    [HttpPatch("{id:int}/inventory")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> UpdateInventory(int id, [FromBody] UpdateInventoryRequest req)
    {
        await svc.UpdateInventoryAsync(id, GetSellerId(), req);
        return Ok(ApiResponse<object>.Ok(null!, "Inventory updated successfully."));
    }

    /// <summary>
    /// Upload one or more product images. Returns the public URL of each
    /// image. Files are pushed to ImgBB (key from appsettings) so the URLs
    /// survive redeploys and aren't bound to the API's wwwroot.
    /// </summary>
    [HttpPost("images/upload")]
    [Consumes("multipart/form-data")]
    [ProducesResponseType(typeof(ApiResponse<List<ImageUploadResponse>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UploadImages([FromForm] List<IFormFile> files)
    {
        if (files is null || files.Count == 0)
            return BadRequest(ApiResponse<object>.Fail("No files provided."));

        var apiKey = config.GetValue<string>("ImgBB:ApiKey");
        if (string.IsNullOrEmpty(apiKey))
            return StatusCode(500, ApiResponse<object>.Fail("ImgBB API key not configured."));

        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
        var results = new List<ImageUploadResponse>();
        using var client = new HttpClient();

        foreach (var file in files.Take(10))
        {
            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowed.Contains(ext))
                return BadRequest(ApiResponse<object>.Fail($"File type '{ext}' is not allowed. Use jpg, png, webp, or gif."));
            if (file.Length > 5 * 1024 * 1024)
                return BadRequest(ApiResponse<object>.Fail("Each file must be under 5 MB."));

            using var ms = new MemoryStream();
            await file.CopyToAsync(ms);
            var base64 = Convert.ToBase64String(ms.ToArray());

            var form = new MultipartFormDataContent
            {
                { new StringContent(base64), "image" },
                { new StringContent(apiKey), "key" }
            };
            var resp = await client.PostAsync("https://api.imgbb.com/1/upload", form);
            if (!resp.IsSuccessStatusCode)
                return StatusCode(500, ApiResponse<object>.Fail($"Failed to upload {file.FileName} to ImgBB."));

            var body = await resp.Content.ReadAsStringAsync();
            using var json = System.Text.Json.JsonDocument.Parse(body);
            var url = json.RootElement.GetProperty("data").GetProperty("display_url").GetString() ?? "";

            results.Add(new ImageUploadResponse
            {
                FileName = file.FileName,
                Url      = url
            });
        }

        return Ok(ApiResponse<List<ImageUploadResponse>>.Ok(results, $"{results.Count} image(s) uploaded."));
    }

    private int GetSellerId() =>
        int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
}
