CREATE PROCEDURE [dbo].[sp_GetStores]
    @City NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            s.[StoreId]    AS [Id],
            s.[StoreName]  AS [Name],
            s.[Address],
            s.[City],
            s.[State],
            s.[Pincode],
            s.[Lat],
            s.[Lng],
            s.[Phone]
        FROM [dbo].[Stores] s
        WHERE s.[IsDeleted] = 0
          AND s.[IsActive]  = 1
          AND (@City IS NULL OR s.[City] = @City)
        ORDER BY s.[City] ASC, s.[StoreName] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
