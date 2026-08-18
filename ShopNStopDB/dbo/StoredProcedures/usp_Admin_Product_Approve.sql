CREATE PROCEDURE [dbo].[usp_Admin_Product_Approve]
    @ProductId  INT,
    @UpdatedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50125, N'Product not found.', 1;

        UPDATE [dbo].[Products]
        SET    [ApprovalStatus] = 2,  -- Approved
               [IsActive]       = 1,
               [UpdatedAt]      = GETUTCDATE(),
               [UpdatedBy]      = @UpdatedBy
        WHERE  [ProductId] = @ProductId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
