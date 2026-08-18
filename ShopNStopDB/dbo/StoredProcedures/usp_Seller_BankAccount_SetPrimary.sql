CREATE PROCEDURE [dbo].[usp_Seller_BankAccount_SetPrimary]
    @BankAccountId INT,
    @SellerId      INT,
    @UpdatedBy     INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[SellerBankAccounts]
            WHERE [BankAccountId] = @BankAccountId AND [SellerId] = @SellerId AND [IsDeleted] = 0)
            THROW 50092, N'Bank account not found for seller.', 1;

        UPDATE [dbo].[SellerBankAccounts]
        SET    [IsPrimary] = 0, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
        WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0;

        UPDATE [dbo].[SellerBankAccounts]
        SET    [IsPrimary] = 1, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
        WHERE  [BankAccountId] = @BankAccountId;

        COMMIT TRANSACTION;

        SELECT [BankAccountId], [IsPrimary]
        FROM   [dbo].[SellerBankAccounts]
        WHERE  [BankAccountId] = @BankAccountId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
