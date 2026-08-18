using Dapper;
using Microsoft.Data.SqlClient;
using ShopNShop.Api.DTOs;

namespace ShopNShop.Api.Repositories;

public interface IWalletRepository
{
    Task<WalletDto> GetBalanceAsync(int userId);
    Task<WalletPageDto> GetWalletPageAsync(int userId, int page, int pageSize);
    Task<decimal> CreditAsync(int userId, decimal amount, string? referenceType, int? referenceId, string description);
}

public class WalletRepository(IConfiguration config) : IWalletRepository
{
    private SqlConnection Conn() => new(config.GetConnectionString("ShopNShop"));

    public async Task<WalletDto> GetBalanceAsync(int userId)
    {
        using var db = Conn();
        var row = await db.QuerySingleAsync<WalletDto>(
            "usp_Wallet_GetBalance",
            new { UserId = userId },
            commandType: System.Data.CommandType.StoredProcedure);
        return row;
    }

    public async Task<WalletPageDto> GetWalletPageAsync(int userId, int page, int pageSize)
    {
        using var db = Conn();

        var wallet = await GetBalanceAsync(userId);

        var rows = (await db.QueryAsync<TxRow>(
            "usp_Wallet_GetTransactions",
            new { UserId = userId, Page = page, PageSize = pageSize },
            commandType: System.Data.CommandType.StoredProcedure)).ToList();

        var totalCount = rows.Count > 0 ? rows[0].TotalCount : 0;

        return new WalletPageDto
        {
            Wallet       = wallet,
            Transactions = rows.Select(r => new WalletTransactionDto
            {
                TransactionId   = r.TransactionId,
                Amount          = r.Amount,
                TransactionType = r.TransactionType,
                ReferenceType   = r.ReferenceType,
                ReferenceId     = r.ReferenceId,
                Description     = r.Description,
                CreatedAt       = r.CreatedAt,
            }).ToList(),
            TotalCount = totalCount,
            TotalPages = pageSize > 0 ? (int)Math.Ceiling((double)totalCount / pageSize) : 1,
        };
    }

    public async Task<decimal> CreditAsync(int userId, decimal amount, string? referenceType, int? referenceId, string description)
    {
        using var db = Conn();
        var row = await db.QuerySingleAsync<CreditResultRow>(
            "usp_Wallet_Credit",
            new { UserId = userId, Amount = amount, ReferenceType = referenceType, ReferenceId = referenceId, Description = description },
            commandType: System.Data.CommandType.StoredProcedure);
        return row.NewBalance;
    }

    private sealed class CreditResultRow
    {
        public decimal NewBalance { get; set; }
        public int     WalletId   { get; set; }
    }

    private sealed class TxRow : WalletTransactionDto
    {
        public int TotalCount { get; set; }
    }
}
