CREATE PROCEDURE [dbo].[usp_Admin_Complaint_UpdateStatus]
    @ComplaintId  INT,
    @Status       TINYINT,            -- 1 Open, 2 InProgress, 3 Resolved, 4 Closed
    @AdminNote    NVARCHAR(MAX) = NULL,
    @AdminUserId  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Status NOT IN (1, 2, 3, 4)
            THROW 50410, N'Invalid status code.', 1;

        DECLARE @UserId INT, @OldStatus TINYINT;
        SELECT @UserId = [UserId], @OldStatus = [Status]
        FROM   [dbo].[Complaints]
        WHERE  [ComplaintId] = @ComplaintId AND [IsDeleted] = 0;

        IF @UserId IS NULL
            THROW 50411, N'Complaint not found.', 1;

        UPDATE [dbo].[Complaints]
        SET    [Status]    = @Status,
               [AdminNote] = COALESCE(@AdminNote, [AdminNote]),
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @AdminUserId
        WHERE  [ComplaintId] = @ComplaintId;

        -- Buyer notification when status changes meaningfully.
        IF @Status <> @OldStatus
        BEGIN
            DECLARE @Label NVARCHAR(20) =
                CASE @Status WHEN 1 THEN N'reopened'
                             WHEN 2 THEN N'in progress'
                             WHEN 3 THEN N'resolved'
                             WHEN 4 THEN N'closed'
                             ELSE       N'updated'
                END;

            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@UserId,
                 N'Complaint ' + @Label,
                 N'Your complaint #' + CAST(@ComplaintId AS NVARCHAR(20)) + N' has been ' + @Label + N'.',
                 4, N'Complaint', @ComplaintId, 1);
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
