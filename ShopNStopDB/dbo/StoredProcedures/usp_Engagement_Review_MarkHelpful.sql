CREATE PROCEDURE [dbo].[usp_Engagement_Review_MarkHelpful]
    @ReviewId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[Reviews]
            WHERE [ReviewId] = @ReviewId AND [IsApproved] = 1 AND [IsDeleted] = 0
        )
            THROW 50160, N'Review not found.', 1;

        UPDATE [dbo].[Reviews]
        SET    [HelpfulCount] = [HelpfulCount] + 1,
               [UpdatedAt]    = GETUTCDATE()
        WHERE  [ReviewId] = @ReviewId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
