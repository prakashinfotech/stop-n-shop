using ShopNShop.Api.DTOs;
using ShopNShop.Api.Repositories;

namespace ShopNShop.Api.Services;

public interface IWalletService
{
    Task<WalletDto> GetBalanceAsync(int userId);
    Task<WalletPageDto> GetWalletPageAsync(int userId, int page, int pageSize);
    Task<WelcomeBonusResult> ClaimWelcomeBonusAsync(int userId);
    Task                     DismissWelcomeBonusAsync(int userId);
}

public class WelcomeBonusResult
{
    public bool    Claimed       { get; set; }
    public decimal AmountCredited{ get; set; }
    public decimal NewBalance    { get; set; }
    public string  Message       { get; set; } = string.Empty;
}

public class WalletService(IWalletRepository repo, IAuthRepository authRepo) : IWalletService
{
    private const decimal WelcomeBonusAmount = 500m;

    public Task<WalletDto> GetBalanceAsync(int userId) =>
        repo.GetBalanceAsync(userId);

    public Task<WalletPageDto> GetWalletPageAsync(int userId, int page, int pageSize) =>
        repo.GetWalletPageAsync(userId, page, pageSize);

    public async Task<WelcomeBonusResult> ClaimWelcomeBonusAsync(int userId)
    {
        // Only first-time logins are eligible. MarkFirstLoginCompleteAsync is idempotent
        // and we use it as the latch — repeat calls credit nothing.
        var profile = await authRepo.GetProfileAsync(userId);
        if (profile is null)
            return new WelcomeBonusResult { Claimed = false, Message = "User not found." };

        if (!profile.IsFirstLogin)
            return new WelcomeBonusResult { Claimed = false, Message = "Welcome bonus already claimed." };

        var newBalance = await repo.CreditAsync(
            userId,
            WelcomeBonusAmount,
            referenceType: "WelcomeBonus",
            referenceId: null,
            description: "Welcome bonus — ₹500 credited on first login.");

        await authRepo.MarkFirstLoginCompleteAsync(userId);

        return new WelcomeBonusResult
        {
            Claimed        = true,
            AmountCredited = WelcomeBonusAmount,
            NewBalance     = newBalance,
            Message        = "Welcome bonus credited.",
        };
    }

    public async Task DismissWelcomeBonusAsync(int userId)
    {
        // Silently no-op if already past first login.
        var profile = await authRepo.GetProfileAsync(userId);
        if (profile is null || !profile.IsFirstLogin) return;
        await authRepo.MarkFirstLoginCompleteAsync(userId);
    }
}
