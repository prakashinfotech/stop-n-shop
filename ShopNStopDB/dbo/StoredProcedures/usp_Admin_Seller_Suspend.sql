CREATE PROCEDURE [dbo].[usp_Admin_Seller_Suspend]
    @SellerId       INT,
    @SuspendReason  NVARCHAR(500) = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
            THROW 50120, N'Seller not found.', 1;

        UPDATE [dbo].[Sellers]
        SET    [IsActive]        = 0,
               [RejectionReason] = @SuspendReason,
               [UpdatedAt]       = GETUTCDATE(),
               [UpdatedBy]       = @UpdatedBy
        WHERE  [SellerId] = @SellerId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
