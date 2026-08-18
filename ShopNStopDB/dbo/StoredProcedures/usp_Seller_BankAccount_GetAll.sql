CREATE PROCEDURE [dbo].[usp_Seller_BankAccount_GetAll]
    @SellerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [BankAccountId], [SellerId], [AccountHolderName], [BankName],
           [AccountNumber], [IfscCode], [BranchName], [IsPrimary], [IsVerified],
           [VerifiedAt], [CreatedAt], [UpdatedAt]
    FROM   [dbo].[SellerBankAccounts]
    WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0
    ORDER  BY [IsPrimary] DESC, [CreatedAt] DESC;
END;
GO
