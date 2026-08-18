using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

/// <summary>
/// Periodically sweeps StockReservations and releases any whose TTL has elapsed,
/// keeping Stock.Reserved counters honest.
/// </summary>
public class ReservationExpiryWorker(
    IServiceScopeFactory scopeFactory,
    ILogger<ReservationExpiryWorker> logger)
    : BackgroundService
{
    private static readonly TimeSpan Interval = TimeSpan.FromMinutes(1);
    private const int BatchSize = 200;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        logger.LogInformation("ReservationExpiryWorker started (interval={Interval})", Interval);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var repo = scope.ServiceProvider.GetRequiredService<IInventoryRepository>();
                var count = await repo.ExpireDueReservationsAsync(BatchSize);
                if (count > 0)
                    logger.LogInformation("Expired {Count} stale reservation(s)", count);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "ReservationExpiryWorker tick failed");
            }

            try { await Task.Delay(Interval, stoppingToken); }
            catch (TaskCanceledException) { /* shutting down */ }
        }
    }
}
