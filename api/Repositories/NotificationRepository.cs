using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface INotificationRepository
{
    Task<NotificationsResultDto> GetByUserAsync(int userId, int page, int pageSize);
    Task MarkReadAsync(int userId, int? notificationId);
    Task<int> SendAsync(int userId, string title, string body, int notificationType, int? entityId = null, string? entityType = null);
}

public class NotificationRepository(IConfiguration config) : INotificationRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<NotificationsResultDto> GetByUserAsync(int userId, int page, int pageSize)
    {
        using var db = Conn();

        var rows = await db.QueryAsync<NotificationRow>(
            "usp_Notification_GetByUser",
            new { UserId = userId, PageNumber = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure);

        var list = rows.ToList();
        var totalCount  = list.Count > 0 ? list[0].TotalCount  : 0;
        var unreadCount = list.Count > 0 ? list[0].UnreadCount : 0;

        return new NotificationsResultDto
        {
            Items = list.Select(r => new NotificationDto
            {
                Id        = r.NotificationId,
                Title     = r.Title,
                Message   = r.Body,
                IsRead    = r.IsRead,
                CreatedAt = r.CreatedAt,
                Type      = r.NotificationType.ToString(),
            }).ToList(),
            TotalCount  = totalCount,
            UnreadCount = unreadCount,
            PageNo      = page,
            PageSize    = pageSize,
        };
    }

    public async Task MarkReadAsync(int userId, int? notificationId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Notification_MarkRead",
            new { UserId = userId, NotificationId = notificationId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<int> SendAsync(int userId, string title, string body, int notificationType, int? entityId = null, string? entityType = null)
    {
        using var db = Conn();
        var result = await db.ExecuteScalarAsync<int>(
            "usp_Notification_Send",
            new
            {
                UserId           = userId,
                Title            = title,
                Body             = body,
                NotificationType = notificationType,
                EntityId         = entityId,
                EntityType       = entityType,
            },
            commandType: System.Data.CommandType.StoredProcedure);
        return result;
    }

    private sealed class NotificationRow
    {
        public int      NotificationId   { get; set; }
        public string   Title            { get; set; } = string.Empty;
        public string   Body             { get; set; } = string.Empty;
        public int      NotificationType { get; set; }
        public int?     EntityId         { get; set; }
        public string?  EntityType       { get; set; }
        public bool     IsRead           { get; set; }
        public DateTime CreatedAt        { get; set; }
        public int      TotalCount       { get; set; }
        public int      UnreadCount      { get; set; }
    }
}
