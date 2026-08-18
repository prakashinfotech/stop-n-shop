CREATE PROCEDURE [dbo].[usp_Wallet_GetTransactions]
    @UserId   INT,
    @Page     INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@Page - 1) * @PageSize;

        SELECT
            wt.[TransactionId],
            wt.[Amount],
            wt.[TransactionType],
            wt.[ReferenceType],
            wt.[ReferenceId],
            wt.[Description],
            wt.[CreatedAt],
            COUNT(*) OVER() AS [TotalCount]
        FROM [dbo].[WalletTransactions] wt
        WHERE wt.[UserId] = @UserId
        ORDER BY wt.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
