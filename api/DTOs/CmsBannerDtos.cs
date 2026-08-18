namespace ShopNShop.Api.DTOs;

public class CmsBannerDto
{
    public int BannerId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? SubTitle { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? MobileImageUrl { get; set; }
    public string? LinkUrl { get; set; }
    public int Section { get; set; }  // BannerType 1–7
    public int SortOrder { get; set; }
    /// <summary>Vertical gap (in pixels) the CMS author wants below this banner in the stack.</summary>
    public int GapBelowPx { get; set; } = 32;
    /// <summary>Optional hex/named colour rendered as the surface behind this banner.</summary>
    public string? BackgroundColor { get; set; }
    public bool IsActive { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class CmsBannerUpsertRequest
{
    public int? BannerId { get; set; }  // null = insert
    public string Title { get; set; } = string.Empty;
    public string? SubTitle { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? MobileImageUrl { get; set; }
    public string? LinkUrl { get; set; }
    public int Section { get; set; }  // 1–7
    public int SortOrder { get; set; }
    public int GapBelowPx { get; set; } = 32;
    public string? BackgroundColor { get; set; }
    public bool IsActive { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
}
