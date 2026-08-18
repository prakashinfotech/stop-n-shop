CREATE PROCEDURE [dbo].[usp_CMS_Banner_Upsert]
    @BannerId       INT            = NULL,  -- NULL = insert
    @Title          NVARCHAR(200),
    @SubTitle       NVARCHAR(300)  = NULL,
    @ImageUrl       NVARCHAR(500),
    @MobileImageUrl NVARCHAR(500)  = NULL,
    @LinkUrl        NVARCHAR(500)  = NULL,
    @BannerType     TINYINT        = NULL,
    @SortOrder      INT            = 0,
    @GapBelowPx     INT            = 32,
    @BackgroundColor NVARCHAR(20)  = NULL,
    @IsActive       BIT            = 1,
    @StartDate      DATETIME2(0)   = NULL,
    @EndDate        DATETIME2(0)   = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @BannerId IS NULL
        BEGIN
            INSERT INTO [dbo].[Banners]
                ([Title], [SubTitle], [ImageUrl], [MobileImageUrl], [LinkUrl], [BannerType],
                 [SortOrder], [GapBelowPx], [BackgroundColor], [IsActive], [StartDate], [EndDate],
                 [CreatedAt], [CreatedBy], [IsDeleted])
            VALUES
                (@Title, @SubTitle, @ImageUrl, @MobileImageUrl, @LinkUrl, @BannerType,
                 @SortOrder, @GapBelowPx, @BackgroundColor, @IsActive, @StartDate, @EndDate,
                 GETUTCDATE(), @UpdatedBy, 0);

            SELECT SCOPE_IDENTITY() AS [BannerId];
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = @BannerId AND [IsDeleted] = 0)
                THROW 50140, N'Banner not found.', 1;

            UPDATE [dbo].[Banners]
            SET    [Title]           = @Title,
                   [SubTitle]        = @SubTitle,
                   [ImageUrl]        = @ImageUrl,
                   [MobileImageUrl]  = @MobileImageUrl,
                   [LinkUrl]         = @LinkUrl,
                   [BannerType]      = @BannerType,
                   [SortOrder]       = @SortOrder,
                   [GapBelowPx]      = @GapBelowPx,
                   [BackgroundColor] = @BackgroundColor,
                   [IsActive]        = @IsActive,
                   [StartDate]       = @StartDate,
                   [EndDate]         = @EndDate,
                   [UpdatedAt]       = GETUTCDATE(),
                   [UpdatedBy]       = @UpdatedBy
            WHERE  [BannerId] = @BannerId;

            SELECT @BannerId AS [BannerId];
        END

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
