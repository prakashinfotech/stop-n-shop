CREATE PROCEDURE [dbo].[usp_Engagement_Review_Approve]
    @ReviewId   INT,
    @UpdatedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Reviews] WHERE [ReviewId] = @ReviewId AND [IsDeleted] = 0)
            THROW 50155, N'Review not found.', 1;

        UPDATE [dbo].[Reviews]
        SET    [IsApproved] = 1,
               [UpdatedAt]  = GETUTCDATE(),
               [UpdatedBy]  = @UpdatedBy
        WHERE  [ReviewId] = @ReviewId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
