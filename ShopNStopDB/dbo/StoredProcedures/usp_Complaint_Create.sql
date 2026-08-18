CREATE PROCEDURE [dbo].[usp_Complaint_Create]
    @UserId    INT,
    @OrderId   INT            = NULL,
    @Category  NVARCHAR(50),
    @Subject   NVARCHAR(300),
    @Body      NVARCHAR(MAX),
    @Source    NVARCHAR(20)   = N'aria'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF LEN(LTRIM(RTRIM(@Subject))) < 3
            THROW 50400, N'Subject must be at least 3 characters.', 1;
        IF LEN(LTRIM(RTRIM(@Body))) < 10
            THROW 50401, N'Please describe the issue (at least 10 characters).', 1;

        -- Defensive: clamp category to the allowed set; coerce unknowns to 'other'.
        DECLARE @Cat NVARCHAR(50) =
            CASE LOWER(LTRIM(RTRIM(@Category)))
                WHEN N'delivery' THEN N'delivery'
                WHEN N'product'  THEN N'product'
                WHEN N'payment'  THEN N'payment'
                WHEN N'account'  THEN N'account'
                ELSE                 N'other'
            END;

        INSERT INTO [dbo].[Complaints]
            ([UserId], [OrderId], [Category], [Subject], [Body], [Source])
        VALUES
            (@UserId, @OrderId, @Cat, @Subject, @Body, @Source);

        DECLARE @NewId INT = SCOPE_IDENTITY();

        -- Notify the buyer so they can find the ticket later.
        INSERT INTO [dbo].[Notifications]
            ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
        VALUES
            (@UserId,
             N'Complaint received',
             N'We logged your complaint (#' + CAST(@NewId AS NVARCHAR(20)) + N'). Our team will review it shortly.',
             4, N'Complaint', @NewId, 1);

        SELECT @NewId AS [ComplaintId];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
