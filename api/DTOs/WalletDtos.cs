namespace ShopNShop.Api.DTOs;

public class WalletDto
{
    public int      WalletId  { get; set; }
    public int      UserId    { get; set; }
    public decimal  Balance   { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class WalletTransactionDto
{
    public int      TransactionId   { get; set; }
    public decimal  Amount          { get; set; }
    public int      TransactionType { get; set; }  // 1=Credit, 2=Debit
    public string?  ReferenceType   { get; set; }
    public int?     ReferenceId     { get; set; }
    public string   Description     { get; set; } = string.Empty;
    public DateTime CreatedAt       { get; set; }
}

public class WalletPageDto
{
    public WalletDto                 Wallet       { get; set; } = new();
    public List<WalletTransactionDto> Transactions { get; set; } = [];
    public int                       TotalCount   { get; set; }
    public int                       TotalPages   { get; set; }
}
