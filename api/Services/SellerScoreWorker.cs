using Microsoft.Extensions.Hosting;

namespace ShopNShop.Api.Services;

/// <summary>
/// Daily recompute of the rolling 30-day performance score for every active seller.
/// </summary>
public class SellerScoreWorker(IServiceProvider sp, ILogger<SellerScoreWorker> log)
    : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromHours(24);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try { await Task.Delay(TimeSpan.FromMinutes(3), stoppingToken); }
        catch (TaskCanceledException) { return; }

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunOnceAsync(stoppingToken);
            }
            catch (Exception ex)
            {
                log.LogError(ex, "SellerScoreWorker iteration failed");
            }

            try { await Task.Delay(Interval, stoppingToken); }
            catch (TaskCanceledException) { return; }
        }
    }

    internal async Task RunOnceAsync(CancellationToken ct)
    {
        using var scope = sp.CreateScope();
        var repo = scope.ServiceProvider.GetRequiredService<Repositories.ISellerLifecycleRepository>();

        var sellers = (await repo.GetAllActiveSellerIdsAsync()).ToList();
        log.LogInformation("Performance score sweep: {Count} active seller(s)", sellers.Count);

        foreach (var sellerId in sellers)
        {
            if (ct.IsCancellationRequested) return;
            try
            {
                await repo.RecomputeScoreAsync(sellerId, DateTime.UtcNow.Date, windowDays: 30);
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Score recompute failed for seller {SellerId}", sellerId);
            }
        }
    }
}
