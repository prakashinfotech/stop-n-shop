using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IDispatcherRepository
{
    Task<DispatcherProfileDto?> GetProfileByUserIdAsync(int userId);
    Task<(List<DispatcherQueueItemDto> Items, int Total)> GetPickupQueueAsync(int dispatcherId, int page, int pageSize);
    Task<DispatcherClaimResultDto> ClaimPickupAsync(int orderItemId, int dispatcherId);
    Task<int> ConfirmPickupAsync(int dispatcherId);
    Task<(List<DispatcherAssignmentDto> Items, int Total)> GetActiveAsync(int dispatcherId, int page, int pageSize);
    Task<DispatcherClaimResultDto> MarkOutForDeliveryAsync(int assignmentId, int dispatcherId);
    Task<DispatcherSendOtpResultDto> SendDeliveryOtpAsync(int assignmentId, int dispatcherId);
    Task<DispatcherClaimResultDto> VerifyDeliveryOtpAsync(int assignmentId, int dispatcherId,
        string otp, string? proofUrl, decimal? gpsLat, decimal? gpsLng, decimal? codCollected);
}

public class DispatcherRepository(IConfiguration config) : IDispatcherRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<DispatcherProfileDto?> GetProfileByUserIdAsync(int userId)
    {
        using var db = Conn();
        return await db.QuerySingleOrDefaultAsync<DispatcherProfileDto>(
            "usp_Dispatcher_GetProfile",
            new { UserId = userId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    // Shape with TotalCount column the SP appends to every row.
    private sealed class QueueRow : DispatcherQueueItemDto { public int TotalCount { get; set; } }

    public async Task<(List<DispatcherQueueItemDto> Items, int Total)> GetPickupQueueAsync(int dispatcherId, int page, int pageSize)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<QueueRow>(
            "usp_Dispatcher_Pickup_GetQueue",
            new { DispatcherId = dispatcherId, Page = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<DispatcherQueueItemDto>().ToList(), total);
    }

    public async Task<DispatcherClaimResultDto> ClaimPickupAsync(int orderItemId, int dispatcherId)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<DispatcherClaimResultDto>(
            "usp_Dispatcher_Pickup_Claim",
            new { OrderItemId = orderItemId, DispatcherId = dispatcherId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<int> ConfirmPickupAsync(int dispatcherId)
    {
        using var db = Conn();
        // SP returns a one-row, one-column result: { Confirmed: <int> }
        return await db.QuerySingleAsync<int>(
            "usp_Dispatcher_Pickup_Confirm",
            new { DispatcherId = dispatcherId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    private sealed class ActiveRow : DispatcherAssignmentDto { public int TotalCount { get; set; } }

    public async Task<(List<DispatcherAssignmentDto> Items, int Total)> GetActiveAsync(int dispatcherId, int page, int pageSize)
    {
        using var db = Conn();
        var rows = (await db.QueryAsync<ActiveRow>(
            "usp_Dispatcher_Active_GetAll",
            new { DispatcherId = dispatcherId, Page = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();
        var total = rows.Count > 0 ? rows[0].TotalCount : 0;
        return (rows.Cast<DispatcherAssignmentDto>().ToList(), total);
    }

    public async Task<DispatcherClaimResultDto> MarkOutForDeliveryAsync(int assignmentId, int dispatcherId)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<DispatcherClaimResultDto>(
            "usp_Dispatcher_OutForDelivery_Mark",
            new { AssignmentId = assignmentId, DispatcherId = dispatcherId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<DispatcherSendOtpResultDto> SendDeliveryOtpAsync(int assignmentId, int dispatcherId)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<DispatcherSendOtpResultDto>(
            "usp_Dispatcher_Delivery_SendOtp",
            new { AssignmentId = assignmentId, DispatcherId = dispatcherId },
            commandType: System.Data.CommandType.StoredProcedure);
    }

    public async Task<DispatcherClaimResultDto> VerifyDeliveryOtpAsync(int assignmentId, int dispatcherId,
        string otp, string? proofUrl, decimal? gpsLat, decimal? gpsLng, decimal? codCollected)
    {
        using var db = Conn();
        return await db.QuerySingleAsync<DispatcherClaimResultDto>(
            "usp_Dispatcher_Delivery_VerifyOtp",
            new
            {
                AssignmentId = assignmentId,
                DispatcherId = dispatcherId,
                Otp          = otp,
                ProofUrl     = proofUrl,
                GpsLat       = gpsLat,
                GpsLng       = gpsLng,
                CodCollected = codCollected,
            },
            commandType: System.Data.CommandType.StoredProcedure);
    }
}
