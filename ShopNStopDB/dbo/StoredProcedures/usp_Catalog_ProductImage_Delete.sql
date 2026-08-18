CREATE PROCEDURE [dbo].[usp_Catalog_ProductImage_Delete]
    @ImageId    INT,
    @DeletedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[ProductImages]
            WHERE [ImageId] = @ImageId AND [IsDeleted] = 0
        )
            THROW 50085, N'Product image not found.', 1;

        UPDATE [dbo].[ProductImages]
        SET    [IsDeleted]  = 1,
               [UpdatedAt]  = GETUTCDATE(),
               [UpdatedBy]  = @DeletedBy
        WHERE  [ImageId] = @ImageId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
