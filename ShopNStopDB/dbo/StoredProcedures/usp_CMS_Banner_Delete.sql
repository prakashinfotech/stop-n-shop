CREATE PROCEDURE [dbo].[usp_CMS_Banner_Delete]
    @BannerId INT,
    @DeletedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = @BannerId AND [IsDeleted] = 0)
            THROW 50140, N'Banner not found.', 1;

        UPDATE [dbo].[Banners]
        SET    [IsDeleted]  = 1,
               [IsActive]   = 0,
               [UpdatedAt]  = GETUTCDATE(),
               [UpdatedBy]  = @DeletedBy
        WHERE  [BannerId] = @BannerId;

        SELECT @BannerId AS [BannerId];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
