using FluentAssertions;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;
using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;
using ShopNShop.Api.Services;

namespace StopNShop.Api.UnitTests;

public class SellerLifecycleServiceTests
{
    private static ISellerLifecycleService NewSvc(Mock<ISellerLifecycleRepository>? repo = null) =>
        new SellerLifecycleService(
            (repo ?? new Mock<ISellerLifecycleRepository>()).Object,
            NullLogger<SellerLifecycleService>.Instance);

    // ── Pure settlement math ─────────────────────────────────────

    [Fact]
    public void ComputeLineMath_uses_seller_specific_commission_when_present()
    {
        var svc = NewSvc();

        var m = svc.ComputeLineMath(gross: 1000m, sellerCommission: 80m, defaultRate: 10m, tdsRate: 1m);

        m.Gross.Should().Be(1000m);
        m.Commission.Should().Be(80m);
        m.Tds.Should().Be(0.80m);
        m.Net.Should().Be(1000m - 80m - 0.80m);
    }

    [Fact]
    public void ComputeLineMath_falls_back_to_default_rate_when_commission_null()
    {
        var svc = NewSvc();

        var m = svc.ComputeLineMath(gross: 1000m, sellerCommission: null, defaultRate: 10m, tdsRate: 1m);

        m.Commission.Should().Be(100m);          // 10% of 1000
        m.Tds.Should().Be(1m);                   // 1% of 100
        m.Net.Should().Be(899m);                 // 1000 - 100 - 1
    }

    [Fact]
    public void ComputeLineMath_subtracts_penalty()
    {
        var svc = NewSvc();

        var m = svc.ComputeLineMath(gross: 500m, sellerCommission: 50m, defaultRate: 10m, tdsRate: 1m, penalty: 25m);

        m.Penalty.Should().Be(25m);
        m.Net.Should().Be(500m - 50m - 0.50m - 25m);
    }

    [Fact]
    public void ComputeLineMath_handles_zero_gross()
    {
        var svc = NewSvc();

        var m = svc.ComputeLineMath(gross: 0m, sellerCommission: null, defaultRate: 10m, tdsRate: 1m);

        m.Commission.Should().Be(0m);
        m.Tds.Should().Be(0m);
        m.Net.Should().Be(0m);
    }

    // ── Settlement window validation ─────────────────────────────

    [Fact]
    public async Task CalculateSettlementAsync_rejects_period_inside_T7_window()
    {
        var svc = NewSvc();
        var today = DateTime.UtcNow.Date;

        var act = () => svc.CalculateSettlementAsync(
            sellerId: 1, periodStart: today.AddDays(-3), periodEnd: today.AddDays(-1), actorUserId: 1);

        await act.Should().ThrowAsync<InvalidOperationException>()
                 .WithMessage("*T+7*");
    }

    [Fact]
    public async Task CalculateSettlementAsync_rejects_inverted_period()
    {
        var svc = NewSvc();

        var act = () => svc.CalculateSettlementAsync(
            sellerId: 1, periodStart: DateTime.UtcNow.Date.AddDays(-10), periodEnd: DateTime.UtcNow.Date.AddDays(-20), actorUserId: 1);

        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task CalculateSettlementAsync_calls_repo_for_valid_window()
    {
        var repo = new Mock<ISellerLifecycleRepository>();
        var expected = new SellerSettlementDto { SettlementId = 42, NetPayout = 880m };
        repo.Setup(r => r.CalculateSettlementAsync(
                    It.IsAny<int>(), It.IsAny<DateTime>(), It.IsAny<DateTime>(), It.IsAny<int>()))
            .ReturnsAsync(expected);

        var svc = NewSvc(repo);
        var start = DateTime.UtcNow.Date.AddDays(-14);
        var end   = DateTime.UtcNow.Date.AddDays(-8);

        var result = await svc.CalculateSettlementAsync(7, start, end, 99);

        result.Should().BeSameAs(expected);
        repo.Verify(r => r.CalculateSettlementAsync(7, start, end, 99), Times.Once);
    }

    // ── Onboarding stage validation ──────────────────────────────

    [Theory]
    [InlineData("business")]
    [InlineData("bank")]
    [InlineData("pickup")]
    [InlineData("documents")]
    [InlineData("agreement")]
    [InlineData("complete")]
    public async Task AdvanceStageAsync_accepts_known_stages(string stage)
    {
        var repo = new Mock<ISellerLifecycleRepository>();
        repo.Setup(r => r.AdvanceStageAsync(It.IsAny<int>(), stage, It.IsAny<int>()))
            .ReturnsAsync(new OnboardingStageDto { SellerId = 1, Stage = stage });

        var svc = NewSvc(repo);

        var result = await svc.AdvanceStageAsync(1, stage, 1);
        result!.Stage.Should().Be(stage);
    }

    [Fact]
    public async Task AdvanceStageAsync_rejects_unknown_stage()
    {
        var svc = NewSvc();

        var act = () => svc.AdvanceStageAsync(1, "warp-drive", 1);
        await act.Should().ThrowAsync<ArgumentException>();
    }

    // ── Document upload validation ───────────────────────────────

    [Theory]
    [InlineData((byte)0)]
    [InlineData((byte)5)]
    [InlineData((byte)99)]
    public async Task UploadDocumentAsync_rejects_invalid_type(byte type)
    {
        var svc = NewSvc();

        var act = () => svc.UploadDocumentAsync(1,
            new UploadSellerDocumentRequest { DocumentType = type, DocumentUrl = "https://x/y.pdf" }, 1);

        await act.Should().ThrowAsync<ArgumentException>();
    }

    [Fact]
    public async Task UploadDocumentAsync_rejects_empty_url()
    {
        var svc = NewSvc();

        var act = () => svc.UploadDocumentAsync(1,
            new UploadSellerDocumentRequest { DocumentType = 1, DocumentUrl = "" }, 1);

        await act.Should().ThrowAsync<ArgumentException>();
    }

    // ── Bank account validation ──────────────────────────────────

    [Fact]
    public async Task AddBankAccountAsync_rejects_missing_account_number()
    {
        var svc = NewSvc();

        var act = () => svc.AddBankAccountAsync(1, new AddSellerBankAccountRequest
        {
            AccountHolderName = "X",
            BankName = "HDFC",
            AccountNumber = "",
            IfscCode = "HDFC0001"
        }, 1);

        await act.Should().ThrowAsync<ArgumentException>();
    }
}
