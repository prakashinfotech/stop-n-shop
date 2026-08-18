using Microsoft.Extensions.Hosting;

namespace ShopNShop.Api.Services;

/// <summary>
/// Nightly sweep — picks up all delivered, unsettled order-items older than T+7
/// and builds one settlement per seller covering the prior calendar week.
/// </summary>
public class SellerSettlementWorker(IServiceProvider sp, ILogger<SellerSettlementWorker> log)
    : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(24);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Initial delay so app start isn't blocked
        try { await Task.Delay(TimeSpan.FromMinutes(2), stoppingToken); }
        catch (TaskCanceledException) { return; }

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunOnceAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                log.LogError(ex, "SellerSettlementWorker iteration failed");
            }

            try { await Task.Delay(Interval, stoppingToken); }
            catch (TaskCanceledException) { return; }
        }
    }

    internal async Task RunOnceAsync(CancellationToken ct)
    {
        var cutoff      = DateTime.UtcNow.Date.AddDays(-7);
        var periodEnd   = cutoff;
        var periodStart = cutoff.AddDays(-6); // 7-day window ending at T-7

        using var scope = sp.CreateScope();
        var repo = scope.ServiceProvider.GetRequiredService<Repositories.ISellerLifecycleRepository>();

        var sellers = (await repo.GetSellersWithDueSettlementsAsync(cutoff)).ToList();
        log.LogInformation("Settlement sweep: {Count} seller(s) have due items as of {Cutoff:O}", sellers.Count, cutoff);

        foreach (var sellerId in sellers)
        {
            if (ct.IsCancellationRequested) return;
            try
            {
                var s = await repo.CalculateSettlementAsync(sellerId, periodStart, periodEnd, calculatedBy: 0);
                if (s is not null)
                    log.LogInformation("Settled seller {SellerId}: settlementId={SettlementId}, net={Net}", sellerId, s.SettlementId, s.NetPayout);
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Settlement failed for seller {SellerId}", sellerId);
            }
        }
    }
}
