using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IEngagementService
{
    Task<ProductReviewsDto> GetProductReviewsAsync(int productId, int? ratingFilter, int page, int pageSize);
    Task<bool> AddReviewAsync(int productId, int userId, AddReviewRequest req);
    Task<List<string>> GetRecentSearchesAsync(int userId, int count = 6);
}

public class EngagementService(IEngagementRepository repo) : IEngagementService
{
    public async Task<ProductReviewsDto> GetProductReviewsAsync(int productId, int? ratingFilter, int page, int pageSize)
    {
        var (items, total) = await repo.GetProductReviewsAsync(productId, ratingFilter, page, pageSize);
        decimal avg = items.Count > 0 ? Math.Round((decimal)items.Average(r => r.Rating), 1) : 0;
        return new ProductReviewsDto
        {
            AverageRating = avg,
            TotalCount    = total,
            Items         = items,
        };
    }

    public Task<bool> AddReviewAsync(int productId, int userId, AddReviewRequest req)
    {
        var comment = req.Comment.Trim();
        return repo.AddReviewAsync(productId, userId, req.Rating, string.Empty, comment);
    }

    public Task<List<string>> GetRecentSearchesAsync(int userId, int count = 6) =>
        repo.GetRecentSearchesAsync(userId, count);
}
