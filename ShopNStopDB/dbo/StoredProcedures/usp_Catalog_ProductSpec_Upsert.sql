CREATE PROCEDURE [dbo].[usp_Catalog_ProductSpec_Upsert]
    @ProductId  INT,
    @SpecKey    NVARCHAR(200),
    @SpecValue  NVARCHAR(500),
    @SortOrder  INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[ProductSpecifications]
        SET    [SpecValue] = @SpecValue,
               [SortOrder] = @SortOrder,
               [IsDeleted] = 0
        WHERE  [ProductId] = @ProductId
          AND  [SpecKey]   = @SpecKey;

        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO [dbo].[ProductSpecifications]
                ([ProductId], [SpecKey], [SpecValue], [SortOrder])
            VALUES
                (@ProductId, @SpecKey, @SpecValue, @SortOrder);
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
