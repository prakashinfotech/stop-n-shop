CREATE PROCEDURE [dbo].[usp_Wallet_Credit]
    @UserId         INT,
    @Amount         DECIMAL(18,2),
    @ReferenceType  NVARCHAR(50)  = NULL,
    @ReferenceId    INT           = NULL,
    @Description    NVARCHAR(300) = N'Wallet credit'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Amount <= 0
            THROW 50080, N'Credit amount must be greater than zero.', 1;

        BEGIN TRANSACTION;

            -- Upsert wallet row
            MERGE [dbo].[Wallets] AS target
            USING (SELECT @UserId AS [UserId]) AS source ON target.[UserId] = source.[UserId]
            WHEN MATCHED THEN
                UPDATE SET
                    [Balance]   = [Balance] + @Amount,
                    [UpdatedAt] = GETUTCDATE()
            WHEN NOT MATCHED THEN
                INSERT ([UserId], [Balance], [CreatedAt], [UpdatedAt])
                VALUES (@UserId, @Amount, GETUTCDATE(), GETUTCDATE());

            DECLARE @WalletId    INT;
            DECLARE @NewBalance  DECIMAL(18,2);

            SELECT @WalletId = [WalletId], @NewBalance = [Balance]
            FROM [dbo].[Wallets]
            WHERE [UserId] = @UserId;

            -- Record transaction
            INSERT INTO [dbo].[WalletTransactions]
                ([WalletId], [UserId], [Amount], [TransactionType],
                 [ReferenceType], [ReferenceId], [Description], [CreatedAt])
            VALUES
                (@WalletId, @UserId, @Amount, 1,
                 @ReferenceType, @ReferenceId, @Description, GETUTCDATE());

        COMMIT TRANSACTION;

        SELECT @NewBalance AS [NewBalance], @WalletId AS [WalletId];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
