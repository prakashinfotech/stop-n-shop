namespace ShopNShop.Api.DTOs;

public class NotificationDto
{
    public int      Id        { get; set; }
    public string   Title     { get; set; } = string.Empty;
    public string   Message   { get; set; } = string.Empty;
    public bool     IsRead    { get; set; }
    public DateTime CreatedAt { get; set; }
    public string?  Type      { get; set; }
}

public class NotificationsResultDto
{
    public List<NotificationDto> Items       { get; set; } = [];
    public int                   TotalCount  { get; set; }
    public int                   UnreadCount { get; set; }
    public int                   PageNo      { get; set; }
    public int                   PageSize    { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling((double)TotalCount / PageSize) : 1;
}
