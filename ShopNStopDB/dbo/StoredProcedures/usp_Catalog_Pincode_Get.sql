CREATE PROCEDURE [dbo].[usp_Catalog_Pincode_Get]
    @Pincode NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            [Pincode],
            [City],
            [State],
            [EstimatedDays],
            CAST(1 AS BIT) AS [IsDeliverable]
        FROM [dbo].[Pincodes]
        WHERE [Pincode]  = @Pincode
          AND [IsActive] = 1;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
