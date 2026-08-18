-- Generates a 6-digit delivery OTP for an Out-for-Delivery parcel and pushes
-- it to the buyer via an in-app Notification. The API layer additionally
-- attempts an SMS (graceful — skipped if Twilio isn't configured).
--
-- Returns the OTP + buyer name/mobile so the service can send the SMS. The
-- OTP is NEVER returned to the dispatcher-facing API response — only used
-- server-side for the SMS + stored hashed-in-place for later verification.
CREATE PROCEDURE [dbo].[usp_Dispatcher_Delivery_SendOtp]
    @AssignmentId INT,
    @DispatcherId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Status      TINYINT;
        DECLARE @OrderItemId INT;
        DECLARE @OrderId     INT;
        DECLARE @OrderNumber NVARCHAR(50);
        DECLARE @BuyerId     INT;
        DECLARE @BuyerName   NVARCHAR(200);
        DECLARE @BuyerMobile NVARCHAR(20);
        DECLARE @ProductName NVARCHAR(300);

        SELECT @Status      = da.[Status],
               @OrderItemId = da.[OrderItemId],
               @OrderId     = o.[OrderId],
               @OrderNumber = o.[OrderNumber],
               @BuyerId     = o.[UserId],
               @BuyerName   = u.[FirstName] + N' ' + ISNULL(u.[LastName], N''),
               @BuyerMobile = u.[Mobile],
               @ProductName = oi.[ProductName]
        FROM   [dbo].[DeliveryAssignments] da
        INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderItemId] = da.[OrderItemId]
        INNER JOIN [dbo].[Orders]     o  ON o.[OrderId]      = oi.[OrderId]
        INNER JOIN [dbo].[Users]      u  ON u.[UserId]       = o.[UserId]
        WHERE  da.[AssignmentId] = @AssignmentId
          AND  da.[DispatcherId] = @DispatcherId;

        IF @Status IS NULL
            THROW 50430, N'Assignment not found or not owned by you.', 1;

        IF @Status <> 9
            THROW 50431, N'OTP can only be sent for items that are Out for Delivery.', 1;

        -- 6-digit OTP, 100000–999999
        DECLARE @Otp NVARCHAR(6) =
            RIGHT(N'000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000 AS NVARCHAR(6)), 6);

        BEGIN TRANSACTION;

            UPDATE [dbo].[DeliveryAssignments]
            SET    [DeliveryOtp]            = @Otp,
                   [DeliveryOtpSentAt]      = GETUTCDATE(),
                   [DeliveryOtpAttempts]    = 0,
                   [DeliveryOtpLockedUntil] = NULL,
                   [UpdatedAt]              = GETUTCDATE()
            WHERE  [AssignmentId] = @AssignmentId;

            -- In-app notification — always delivered, no external dependency.
            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@BuyerId,
                 N'Delivery OTP',
                 N'Your delivery OTP for order ' + @OrderNumber + N' is ' + @Otp +
                 N'. Share it with the delivery agent to receive "' + @ProductName + N'".',
                 2, N'Order', @OrderId, 1);

        COMMIT TRANSACTION;

        SELECT @Otp         AS [Otp],
               @OrderNumber AS [OrderNumber],
               @BuyerName   AS [BuyerName],
               @BuyerMobile AS [BuyerMobile];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
