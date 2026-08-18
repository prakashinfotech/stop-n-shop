using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface INotificationService
{
    Task<NotificationsResultDto> GetByUserAsync(int userId, int page, int pageSize);
    Task MarkReadAsync(int userId, int? notificationId);
    Task SendAsync(int userId, string title, string body, int notificationType, int? entityId = null, string? entityType = null);
}

public class NotificationService(INotificationRepository repo) : INotificationService
{
    public Task<NotificationsResultDto> GetByUserAsync(int userId, int page, int pageSize) =>
        repo.GetByUserAsync(userId, page, pageSize);

    public Task MarkReadAsync(int userId, int? notificationId) =>
        repo.MarkReadAsync(userId, notificationId);

    public Task SendAsync(int userId, string title, string body, int notificationType, int? entityId = null, string? entityType = null) =>
        repo.SendAsync(userId, title, body, notificationType, entityId, entityType);
}
