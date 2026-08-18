CREATE PROCEDURE [dbo].[usp_CMS_HomeSection_Upsert]
    @SectionId      INT            = NULL,  -- NULL = insert
    @SectionName    NVARCHAR(100),
    @Title          NVARCHAR(200)  = NULL,
    @SubTitle       NVARCHAR(300)  = NULL,
    @SectionType    NVARCHAR(50),
    @SortOrder      INT            = 0,
    @IsActive       BIT            = 1,
    @FilterJson     NVARCHAR(MAX)  = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @SectionId IS NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM [dbo].[HomeSections] WHERE [SectionName] = @SectionName AND [IsDeleted] = 0)
                THROW 50145, N'A section with this name already exists.', 1;

            INSERT INTO [dbo].[HomeSections]
                ([SectionName], [Title], [SubTitle], [SectionType],
                 [SortOrder], [IsActive], [FilterJson],
                 [CreatedAt], [CreatedBy], [IsDeleted])
            VALUES
                (@SectionName, @Title, @SubTitle, @SectionType,
                 @SortOrder, @IsActive, @FilterJson,
                 GETUTCDATE(), @UpdatedBy, 0);

            SELECT SCOPE_IDENTITY() AS [SectionId];
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM [dbo].[HomeSections] WHERE [SectionId] = @SectionId AND [IsDeleted] = 0)
                THROW 50146, N'Home section not found.', 1;

            UPDATE [dbo].[HomeSections]
            SET    [SectionName]  = @SectionName,
                   [Title]        = @Title,
                   [SubTitle]     = @SubTitle,
                   [SectionType]  = @SectionType,
                   [SortOrder]    = @SortOrder,
                   [IsActive]     = @IsActive,
                   [FilterJson]   = @FilterJson,
                   [UpdatedAt]    = GETUTCDATE(),
                   [UpdatedBy]    = @UpdatedBy
            WHERE  [SectionId] = @SectionId;

            SELECT @SectionId AS [SectionId];
        END

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
