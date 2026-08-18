using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IBrandRepository
{
    Task<List<BrandDto>> GetAllAsync();
}

public class BrandRepository(IConfiguration config) : IBrandRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<List<BrandDto>> GetAllAsync()
    {
        using var db = Conn();
        var result = await db.QueryAsync<BrandDto>(
            "SELECT BrandId AS Id, BrandName AS Name FROM Brands WHERE IsDeleted = 0 AND IsActive = 1 ORDER BY BrandName",
            commandType: System.Data.CommandType.Text);
        return [.. result];
    }
}
