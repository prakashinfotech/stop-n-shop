using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IComplaintService
{
    Task<int> CreateAsync(int userId, CreateComplaintRequest req);
    Task<(List<ComplaintDto> Items, int Total)>      GetByUserAsync(int userId, int page, int pageSize);
    Task<(List<AdminComplaintDto> Items, int Total)> AdminGetAllAsync(byte? status, string? category, string? search, int page, int pageSize);
    Task UpdateStatusAsync(int complaintId, byte status, string? adminNote, int adminUserId);
}

public class ComplaintService(IComplaintRepository repo) : IComplaintService
{
    public Task<int> CreateAsync(int userId, CreateComplaintRequest req) =>
        repo.CreateAsync(userId, req);

    public Task<(List<ComplaintDto> Items, int Total)> GetByUserAsync(int userId, int page, int pageSize) =>
        repo.GetByUserAsync(userId, page, pageSize);

    public Task<(List<AdminComplaintDto> Items, int Total)> AdminGetAllAsync(byte? status, string? category, string? search, int page, int pageSize) =>
        repo.AdminGetAllAsync(status, category, search, page, pageSize);

    public Task UpdateStatusAsync(int complaintId, byte status, string? adminNote, int adminUserId) =>
        repo.UpdateStatusAsync(complaintId, status, adminNote, adminUserId);
}
