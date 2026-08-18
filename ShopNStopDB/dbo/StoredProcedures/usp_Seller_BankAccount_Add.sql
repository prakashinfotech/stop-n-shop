CREATE PROCEDURE [dbo].[usp_Seller_BankAccount_Add]
    @SellerId           INT,
    @AccountHolderName  NVARCHAR(200),
    @BankName           NVARCHAR(100),
    @AccountNumber      NVARCHAR(50),
    @IfscCode           NVARCHAR(20),
    @BranchName         NVARCHAR(200) = NULL,
    @IsPrimary          BIT = 0,
    @CreatedBy          INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Mandatory-primary rule: every seller must have exactly one primary
        -- bank account so settlement payouts have an unambiguous destination.
        -- If this is the seller's first bank account, force IsPrimary = 1
        -- regardless of what the caller asked. Defends against UI bypass.
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[SellerBankAccounts]
            WHERE [SellerId] = @SellerId AND [IsDeleted] = 0
        )
            SET @IsPrimary = 1;

        IF @IsPrimary = 1
            UPDATE [dbo].[SellerBankAccounts]
            SET    [IsPrimary] = 0,
                   [UpdatedAt] = GETUTCDATE(),
                   [UpdatedBy] = @CreatedBy
            WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0;

        INSERT INTO [dbo].[SellerBankAccounts]
            ([SellerId], [AccountHolderName], [BankName], [AccountNumber], [IfscCode], [BranchName],
             [IsPrimary], [IsVerified], [CreatedBy], [UpdatedBy])
        VALUES
            (@SellerId, @AccountHolderName, @BankName, @AccountNumber, @IfscCode, @BranchName,
             @IsPrimary, 0, @CreatedBy, @CreatedBy);

        DECLARE @NewId INT = SCOPE_IDENTITY();
        COMMIT TRANSACTION;

        SELECT [BankAccountId], [SellerId], [AccountHolderName], [BankName],
               [AccountNumber], [IfscCode], [BranchName], [IsPrimary], [IsVerified], [CreatedAt]
        FROM   [dbo].[SellerBankAccounts]
        WHERE  [BankAccountId] = @NewId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
