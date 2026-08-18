-- Verifies the buyer's delivery OTP and, on success, completes the delivery:
-- moves status 9 → 5 (Delivered) on both DeliveryAssignments + OrderItems,
-- stamps proof (photo URL + GPS), records COD collection, writes a DELIVERED
-- tracking entry + a DeliveryAttempts row, and stamps Orders.DeliveredAt.
--
-- Guards:
--   • assignment must be owned by @DispatcherId and in status 9
--   • not locked (DeliveryOtpLockedUntil in the future)
--   • OTP not expired (sent within last 15 minutes)
--   • OTP matches; 3 wrong attempts → 5-minute lockout (THROW 50436)
CREATE PROCEDURE [dbo].[usp_Dispatcher_Delivery_VerifyOtp]
    @AssignmentId  INT,
    @DispatcherId  INT,
    @Otp           NVARCHAR(6),
    @ProofUrl      NVARCHAR(500) = NULL,
    @GpsLat        DECIMAL(9,6)  = NULL,
    @GpsLng        DECIMAL(9,6)  = NULL,
    @CodCollected  DECIMAL(18,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Status       TINYINT;
        DECLARE @StoredOtp    NVARCHAR(6);
        DECLARE @SentAt       DATETIME2(0);
        DECLARE @Attempts     TINYINT;
        DECLARE @LockedUntil  DATETIME2(0);
        DECLARE @OrderItemId  INT;
        DECLARE @OrderId      INT;
        DECLARE @OrderNumber  NVARCHAR(50);
        DECLARE @ProductName  NVARCHAR(300);
        DECLARE @AttemptNum   TINYINT;

        SELECT @Status      = da.[Status],
               @StoredOtp   = da.[DeliveryOtp],
               @SentAt      = da.[DeliveryOtpSentAt],
               @Attempts    = da.[DeliveryOtpAttempts],
               @LockedUntil = da.[DeliveryOtpLockedUntil],
               @OrderItemId = da.[OrderItemId],
               @AttemptNum  = da.[AttemptNumber],
               @OrderId     = o.[OrderId],
               @OrderNumber = o.[OrderNumber],
               @ProductName = oi.[ProductName]
        FROM   [dbo].[DeliveryAssignments] da WITH (UPDLOCK, ROWLOCK)
        INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderItemId] = da.[OrderItemId]
        INNER JOIN [dbo].[Orders]     o  ON o.[OrderId]      = oi.[OrderId]
        WHERE  da.[AssignmentId] = @AssignmentId
          AND  da.[DispatcherId] = @DispatcherId;

        IF @Status IS NULL
            THROW 50432, N'Assignment not found or not owned by you.', 1;

        IF @Status <> 9
            THROW 50433, N'This item is not out for delivery.', 1;

        IF @StoredOtp IS NULL
            THROW 50434, N'No OTP has been sent. Tap "Send OTP" first.', 1;

        IF @LockedUntil IS NOT NULL AND @LockedUntil > GETUTCDATE()
            THROW 50436, N'Too many wrong attempts. Try again in a few minutes or call the buyer.', 1;

        -- 15-minute expiry
        IF DATEDIFF(MINUTE, @SentAt, GETUTCDATE()) >= 15
            THROW 50435, N'OTP expired. Send a fresh one.', 1;

        -- Wrong OTP path
        IF @StoredOtp <> @Otp
        BEGIN
            DECLARE @NewAttempts TINYINT = @Attempts + 1;
            UPDATE [dbo].[DeliveryAssignments]
            SET    [DeliveryOtpAttempts]    = @NewAttempts,
                   [DeliveryOtpLockedUntil] = CASE WHEN @NewAttempts >= 3
                                                   THEN DATEADD(MINUTE, 5, GETUTCDATE())
                                                   ELSE [DeliveryOtpLockedUntil] END,
                   [UpdatedAt]              = GETUTCDATE()
            WHERE  [AssignmentId] = @AssignmentId;

            -- Forensic log
            INSERT INTO [dbo].[DeliveryAttempts]
                ([AssignmentId], [AttemptNumber], [Outcome], [Notes], [GpsLat], [GpsLng])
            VALUES
                (@AssignmentId, @AttemptNum, N'OTP_FAIL',
                 N'Wrong OTP entered (attempt ' + CAST(@NewAttempts AS NVARCHAR(3)) + N').',
                 @GpsLat, @GpsLng);

            IF @NewAttempts >= 3
                THROW 50436, N'Too many wrong attempts. Locked for 5 minutes — call the buyer to confirm.', 1;
            ELSE
                THROW 50437, N'Incorrect OTP. Please re-check with the buyer.', 1;
        END

        -- Correct OTP → complete delivery
        BEGIN TRANSACTION;

            UPDATE [dbo].[DeliveryAssignments]
            SET    [Status]           = 5,
                   [DeliveredAt]      = GETUTCDATE(),
                   [DeliveryProofUrl] = @ProofUrl,
                   [DeliveryGpsLat]   = @GpsLat,
                   [DeliveryGpsLng]   = @GpsLng,
                   [CodCollected]     = @CodCollected,
                   [CodSettledAt]     = CASE WHEN @CodCollected IS NOT NULL THEN GETUTCDATE() ELSE NULL END,
                   [DeliveryOtp]      = NULL,                 -- one-time use
                   [UpdatedAt]        = GETUTCDATE()
            WHERE  [AssignmentId] = @AssignmentId;

            UPDATE [dbo].[OrderItems]
            SET    [OrderStatus] = 5,
                   [UpdatedAt]   = GETUTCDATE()
            WHERE  [OrderItemId] = @OrderItemId;

            -- Stamp the order header's DeliveredAt (settlement calc reads this).
            UPDATE [dbo].[Orders]
            SET    [DeliveredAt] = COALESCE([DeliveredAt], GETUTCDATE()),
                   [UpdatedAt]   = GETUTCDATE()
            WHERE  [OrderId] = @OrderId;

            -- Live position no longer relevant (defensive — L6 table may not have a row).
            DELETE FROM [dbo].[DispatcherCurrentPositions] WHERE [AssignmentId] = @AssignmentId;

            INSERT INTO [dbo].[DeliveryAttempts]
                ([AssignmentId], [AttemptNumber], [Outcome], [Notes], [GpsLat], [GpsLng])
            VALUES
                (@AssignmentId, @AttemptNum, N'DELIVERED',
                 CASE WHEN @CodCollected IS NOT NULL
                      THEN N'Delivered. COD collected: ' + CAST(@CodCollected AS NVARCHAR(20))
                      ELSE N'Delivered (prepaid).' END,
                 @GpsLat, @GpsLng);

            INSERT INTO [dbo].[OrderTrackings]
                ([OrderId], [OrderItemId], [Status], [Note], [ChangedAt])
            VALUES
                (@OrderId, @OrderItemId, N'DELIVERED',
                 N'"' + @ProductName + N'" delivered to the buyer (OTP verified).', GETUTCDATE());

        COMMIT TRANSACTION;

        SELECT @AssignmentId AS [AssignmentId],
               @OrderItemId  AS [OrderItemId],
               5             AS [Status],
               @OrderNumber  AS [OrderNumber];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
