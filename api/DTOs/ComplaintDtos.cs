namespace ShopNShop.Api.DTOs;

public record CreateComplaintRequest(
    string  Category,
    string  Subject,
    string  Body,
    int?    OrderId,
    string? Source);   // 'aria' | 'web' | 'support' — server clamps to allowed values

public class ComplaintDto
{
    public int       ComplaintId  { get; set; }
    public int?      OrderId      { get; set; }
    public string?   OrderNumber  { get; set; }
    public string    Category     { get; set; } = "other";
    public string    Subject      { get; set; } = string.Empty;
    public string    Body         { get; set; } = string.Empty;
    public byte      Status       { get; set; }     // 1 Open · 2 InProgress · 3 Resolved · 4 Closed
    public string?   AdminNote    { get; set; }
    public DateTime  CreatedAt    { get; set; }
    public DateTime  UpdatedAt    { get; set; }
}

public class AdminComplaintDto : ComplaintDto
{
    public int     UserId    { get; set; }
    public string? UserName  { get; set; }
    public string? UserEmail { get; set; }
    public string  Source    { get; set; } = "aria";
}

public record UpdateComplaintStatusRequest(byte Status, string? AdminNote);
