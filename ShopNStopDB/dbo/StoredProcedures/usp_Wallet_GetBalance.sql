CREATE PROCEDURE [dbo].[usp_Wallet_GetBalance]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Return existing wallet or default 0 balance if none exists
        SELECT
            ISNULL(w.[WalletId], 0)         AS [WalletId],
            @UserId                          AS [UserId],
            ISNULL(w.[Balance], 0.00)        AS [Balance],
            ISNULL(w.[UpdatedAt], GETUTCDATE()) AS [UpdatedAt]
        FROM (SELECT 1 AS [x]) AS [dummy]
        LEFT JOIN [dbo].[Wallets] w ON w.[UserId] = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
