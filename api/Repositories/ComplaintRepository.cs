using System.Data;
using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IComplaintRepository
{
    Task<int> CreateAsync(int userId, CreateComplaintRequest req);
    Task<(List<ComplaintDto> Items, int Total)>      GetByUserAsync(int userId, int page, int pageSize);
    Task<(List<AdminComplaintDto> Items, int Total)> AdminGetAllAsync(byte? status, string? category, string? search, int page, int pageSize);
    Task UpdateStatusAsync(int complaintId, byte status, string? adminNote, int adminUserId);
}

public class ComplaintRepository(IConfiguration config) : IComplaintRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<int> CreateAsync(int userId, CreateComplaintRequest req)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<int>(
            "usp_Complaint_Create",
            new
            {
                UserId   = userId,
                req.OrderId,
                req.Category,
                req.Subject,
                req.Body,
                Source   = string.IsNullOrWhiteSpace(req.Source) ? "aria" : req.Source,
            },
            commandType: CommandType.StoredProcedure);
    }

    private sealed class UserRow : ComplaintDto { public int TotalCount { get; set; } }

    public async Task<(List<ComplaintDto> Items, int Total)> GetByUserAsync(int userId, int page, int pageSize)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<UserRow>(
            "usp_Complaint_GetByUser",
            new { UserId = userId, Page = page, PageSize = pageSize },
            commandType: CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<ComplaintDto>().ToList(), total);
    }

    private sealed class AdminRow : AdminComplaintDto { public int TotalCount { get; set; } }

    public async Task<(List<AdminComplaintDto> Items, int Total)> AdminGetAllAsync(byte? status, string? category, string? search, int page, int pageSize)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<AdminRow>(
            "usp_Admin_Complaint_GetAll",
            new { Status = status, Category = category, SearchTerm = search, Page = page, PageSize = pageSize },
            commandType: CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<AdminComplaintDto>().ToList(), total);
    }

    public async Task UpdateStatusAsync(int complaintId, byte status, string? adminNote, int adminUserId)
    {
        using var db = Conn();
        await db.ExecuteAsync(
            "usp_Admin_Complaint_UpdateStatus",
            new { ComplaintId = complaintId, Status = status, AdminNote = adminNote, AdminUserId = adminUserId },
            commandType: CommandType.StoredProcedure);
    }
}
