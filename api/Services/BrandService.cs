using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IBrandService
{
    Task<List<BrandDto>> GetAllAsync();
}

public class BrandService(IBrandRepository repo) : IBrandService
{
    public async Task<List<BrandDto>> GetAllAsync() =>
        await repo.GetAllAsync();
}
