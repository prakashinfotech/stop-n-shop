using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.Common;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IEngagementRepository
{
    Task<(List<ReviewDto> Items, int TotalCount)> GetProductReviewsAsync(int productId, int? ratingFilter, int page, int pageSize);
    Task<bool> AddReviewAsync(int productId, int userId, int rating, string title, string body);
    Task<List<string>> GetRecentSearchesAsync(int userId, int count = 6);
}

public class EngagementRepository(IConfiguration config) : IEngagementRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<(List<ReviewDto> Items, int TotalCount)> GetProductReviewsAsync(
        int productId, int? ratingFilter, int page, int pageSize)
    {
        using var db = Conn();
        using var multi = await db.QueryMultipleAsync(
            "usp_Engagement_Review_GetByProduct",
            new { ProductId = productId, PageNumber = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure);

        // First result set: rating summary (we use TotalReviews for total count).
        var summary = await multi.ReadFirstOrDefaultAsync();
        int total = summary != null ? (int)(summary.TotalReviews ?? 0) : 0;

        // Second result set: paginated review rows.
        var rows = (await multi.ReadAsync()).ToList();

        var items = rows.Select(r =>
        {
            string first = (string?)r.FirstName ?? string.Empty;
            string last  = (string?)r.LastName  ?? string.Empty;
            string name  = (first + " " + last).Trim();
            return new ReviewDto
            {
                ReviewId     = (int)(r.ReviewId ?? 0),
                ReviewerName = string.IsNullOrWhiteSpace(name) ? "Anonymous" : name,
                Rating       = (int)(r.Rating ?? 0),
                Title        = (string?)r.Title,
                Body         = (string?)r.Body,
                CreatedAt    = (DateTime)(r.CreatedAt ?? DateTime.UtcNow),
                HelpfulCount = (int)(r.HelpfulCount ?? 0),
            };
        }).ToList();
        _ = ratingFilter; // rating filter not supported by this SP

        return (items, total);
    }

    /// <summary>Last N distinct search terms (newest first) for the home-page chip row.</summary>
    public async Task<List<string>> GetRecentSearchesAsync(int userId, int count = 6)
    {
        using var db = Conn();
        var rows = await db.QueryAsync<string>(
            "usp_Engagement_SearchLog_GetRecent",
            new { UserId = userId, Count = count },
            commandType: System.Data.CommandType.StoredProcedure);
        return rows.AsList();
    }

    public async Task<bool> AddReviewAsync(int productId, int userId, int rating, string title, string body)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Engagement_Review_Add",
            new
            {
                ProductId   = productId,
                UserId      = userId,
                OrderItemId = (int?)null,
                Rating      = rating,
                Title       = title,
                Body        = body,
            },
            commandType: System.Data.CommandType.StoredProcedure);
        return true;
    }
}
