using System.Text.Json;
using FluentAssertions;
using FluentValidation;
using FluentValidation.Results;
using Moq;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;
using ShopNShop.Api.Services;
using Xunit;

namespace StopNShop.Api.IntegrationTests;

/// <summary>
/// Unit tests for <see cref="AdminService"/>. Pure mocks — no HTTP, no DB.
/// Verifies that every admin write is paired with an audit-log entry carrying
/// the correct verb on the new-values envelope.
/// </summary>
public class AdminServiceTests
{
    private const int AdminId = 99;
    private const string Ip = "10.0.0.1";

    private readonly Mock<IAdminRepository> _repo = new(MockBehavior.Strict);
    private readonly Mock<IValidator<UpdateCouponRequest>>     _couponValidator       = new();
    private readonly Mock<IValidator<ForceCancelOrderRequest>> _forceCancelValidator  = new();
    private readonly Mock<IValidator<ManualRefundRequest>>     _manualRefundValidator = new();

    private AdminService Sut() => new(
        _repo.Object,
        _couponValidator.Object,
        _forceCancelValidator.Object,
        _manualRefundValidator.Object);

    private void ExpectAudit(string table, int recordId, string expectedVerb)
    {
        _repo.Setup(r => r.WriteAuditAsync(
                table, recordId, "UPDATE",
                It.IsAny<string?>(),
                It.Is<string>(s => ExtractVerb(s) == expectedVerb),
                AdminId, Ip))
            .ReturnsAsync(1L);
    }

    private static string? ExtractVerb(string json)
    {
        using var doc = JsonDocument.Parse(json);
        return doc.RootElement.GetProperty("verb").GetString();
    }

    [Fact]
    public async Task ApproveSellerAsync_writes_audit_with_APPROVE_SELLER_verb()
    {
        _repo.Setup(r => r.ApproveSellerAsync(42, AdminId)).Returns(Task.CompletedTask);
        ExpectAudit("Sellers", 42, "APPROVE_SELLER");

        await Sut().ApproveSellerAsync(42, AdminId, Ip);

        _repo.VerifyAll();
    }

    [Fact]
    public async Task RejectSellerAsync_writes_audit_with_reason()
    {
        const string reason = "incomplete docs";
        _repo.Setup(r => r.RejectSellerAsync(7, AdminId, reason)).Returns(Task.CompletedTask);
        _repo.Setup(r => r.WriteAuditAsync(
                "Sellers", 7, "UPDATE",
                null,
                It.Is<string>(s => ExtractVerb(s) == "REJECT_SELLER" && s.Contains(reason)),
                AdminId, Ip))
            .ReturnsAsync(1L);

        await Sut().RejectSellerAsync(7, AdminId, reason, Ip);

        _repo.VerifyAll();
    }

    [Fact]
    public async Task SuspendUserAsync_writes_audit()
    {
        _repo.Setup(r => r.SuspendUserAsync(11, AdminId, "abuse")).Returns(Task.CompletedTask);
        ExpectAudit("Users", 11, "SUSPEND_USER");

        await Sut().SuspendUserAsync(11, AdminId, "abuse", Ip);

        _repo.VerifyAll();
    }

    [Fact]
    public async Task DeleteCouponAsync_writes_audit_with_DELETE_COUPON_verb()
    {
        _repo.Setup(r => r.DeleteCouponAsync(3, AdminId)).Returns(Task.CompletedTask);
        ExpectAudit("Coupons", 3, "DELETE_COUPON");

        await Sut().DeleteCouponAsync(3, AdminId, Ip);

        _repo.VerifyAll();
    }

    [Fact]
    public async Task ForceCancelOrderAsync_on_valid_input_writes_audit()
    {
        var req = new ForceCancelOrderRequest("admin chargeback");
        _forceCancelValidator
            .Setup(v => v.ValidateAsync(It.IsAny<ForceCancelOrderRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidationResult());

        _repo.Setup(r => r.ForceCancelOrderAsync(55, AdminId, req.Reason)).Returns(Task.CompletedTask);
        ExpectAudit("Orders", 55, "FORCE_CANCEL_ORDER");

        await Sut().ForceCancelOrderAsync(55, AdminId, req, Ip);

        _repo.VerifyAll();
    }

    [Fact]
    public async Task ManualRefundOrderAsync_writes_audit_with_amount_in_payload()
    {
        var req = new ManualRefundRequest(250.00m, "damaged", "pay_abc");
        _manualRefundValidator
            .Setup(v => v.ValidateAsync(It.IsAny<ManualRefundRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ValidationResult());

        _repo.Setup(r => r.ManualRefundOrderAsync(77, AdminId, 250.00m, "damaged", "pay_abc")).Returns(Task.CompletedTask);
        _repo.Setup(r => r.WriteAuditAsync(
                "Orders", 77, "UPDATE",
                null,
                It.Is<string>(s =>
                    ExtractVerb(s) == "MANUAL_REFUND_ORDER" &&
                    s.Contains("250") &&
                    s.Contains("pay_abc")),
                AdminId, Ip))
            .ReturnsAsync(1L);

        await Sut().ManualRefundOrderAsync(77, AdminId, req, Ip);

        _repo.VerifyAll();
    }

    [Fact]
    public async Task Reads_pass_through_without_writing_audit()
    {
        _repo.Setup(r => r.GetDashboardStatsAsync())
             .ReturnsAsync(new AdminStatsDto { TotalBuyers = 5, TotalOrders = 12 });

        var stats = await Sut().GetDashboardStatsAsync();

        stats.TotalOrders.Should().Be(12);
        _repo.Verify(r => r.WriteAuditAsync(
            It.IsAny<string>(), It.IsAny<int>(), It.IsAny<string>(),
            It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<string?>()), Times.Never);
    }
}
