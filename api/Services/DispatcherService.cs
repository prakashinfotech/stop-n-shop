using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IDispatcherService
{
    Task<DispatcherProfileDto?> GetProfileByUserIdAsync(int userId);
    Task<(List<DispatcherQueueItemDto> Items, int Total)> GetPickupQueueAsync(int dispatcherId, int page, int pageSize);
    Task<DispatcherClaimResultDto> ClaimPickupAsync(int orderItemId, int dispatcherId);
    Task<int> ConfirmPickupAsync(int dispatcherId);
    Task<(List<DispatcherAssignmentDto> Items, int Total)> GetActiveAsync(int dispatcherId, int page, int pageSize);
    Task<DispatcherClaimResultDto> MarkOutForDeliveryAsync(int assignmentId, int dispatcherId);
    /// <summary>Generates the OTP (SP writes the in-app notification) and best-effort
    /// SMSes it. Returns whether the SMS was actually dispatched.</summary>
    Task<(string OrderNumber, bool SmsSent)> SendDeliveryOtpAsync(int assignmentId, int dispatcherId);
    Task<DispatcherClaimResultDto> VerifyDeliveryOtpAsync(int assignmentId, int dispatcherId,
        DispatcherCompleteDeliveryRequest req);
}

/// <summary>Mostly passthrough to SPs (transactions, status guards, ownership
/// checks live there). The one piece of real logic is the OTP send, which
/// fans out to the SMS side-channel after the SP writes the in-app OTP.</summary>
public class DispatcherService(IDispatcherRepository repo, ISmsService sms) : IDispatcherService
{
    public Task<DispatcherProfileDto?> GetProfileByUserIdAsync(int userId) =>
        repo.GetProfileByUserIdAsync(userId);

    public Task<(List<DispatcherQueueItemDto> Items, int Total)> GetPickupQueueAsync(int dispatcherId, int page, int pageSize) =>
        repo.GetPickupQueueAsync(dispatcherId, page, pageSize);

    public Task<DispatcherClaimResultDto> ClaimPickupAsync(int orderItemId, int dispatcherId) =>
        repo.ClaimPickupAsync(orderItemId, dispatcherId);

    public Task<int> ConfirmPickupAsync(int dispatcherId) =>
        repo.ConfirmPickupAsync(dispatcherId);

    public Task<(List<DispatcherAssignmentDto> Items, int Total)> GetActiveAsync(int dispatcherId, int page, int pageSize) =>
        repo.GetActiveAsync(dispatcherId, page, pageSize);

    public Task<DispatcherClaimResultDto> MarkOutForDeliveryAsync(int assignmentId, int dispatcherId) =>
        repo.MarkOutForDeliveryAsync(assignmentId, dispatcherId);

    public async Task<(string OrderNumber, bool SmsSent)> SendDeliveryOtpAsync(int assignmentId, int dispatcherId)
    {
        // SP generates the OTP + writes the in-app notification (always delivered).
        var r = await repo.SendDeliveryOtpAsync(assignmentId, dispatcherId);

        // Best-effort SMS side channel — never blocks or throws.
        var smsSent = await sms.SendAsync(
            r.BuyerMobile ?? string.Empty,
            $"Your StopNShop delivery OTP for order {r.OrderNumber} is {r.Otp}. " +
            $"Share it with the delivery agent. Valid 15 minutes.");

        return (r.OrderNumber, smsSent);
    }

    public Task<DispatcherClaimResultDto> VerifyDeliveryOtpAsync(int assignmentId, int dispatcherId,
        DispatcherCompleteDeliveryRequest req) =>
        repo.VerifyDeliveryOtpAsync(assignmentId, dispatcherId,
            req.Otp, req.ProofPhotoUrl, req.GpsLat, req.GpsLng, req.CodAmount);
}
