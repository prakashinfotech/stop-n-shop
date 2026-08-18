/*
 * 2026-05-28 — Dispatcher L3: delivery OTP flow
 *
 * Adds OTP attempt/lockout columns to DeliveryAssignments and the two SPs
 * that drive the delivery completion:
 *   • usp_Dispatcher_Delivery_SendOtp   — generate 6-digit OTP + in-app notification
 *   • usp_Dispatcher_Delivery_VerifyOtp — verify, mark delivered, proof + COD
 *
 * Idempotent: column adds guarded by COL_LENGTH; SPs are DROP+CREATE.
 *
 * Apply:
 *   docker cp db/patches/2026_05_28_dispatcher_delivery_otp.sql stopnshop-db:/tmp/otp.sql
 *   docker exec -i stopnshop-db /opt/mssql-tools18/bin/sqlcmd \
 *     -S localhost -U sa -P "$SA_PASSWORD" -C -d ShopNShop_db -b -I -i /tmp/otp.sql
 */

SET NOCOUNT ON;

------------------------------------------------------------------------------
-- 1. OTP attempt + lockout columns on DeliveryAssignments
------------------------------------------------------------------------------
IF COL_LENGTH('dbo.DeliveryAssignments', 'DeliveryOtpAttempts') IS NULL
BEGIN
    PRINT '[L3] Adding DeliveryOtpAttempts...';
    ALTER TABLE [dbo].[DeliveryAssignments]
        ADD [DeliveryOtpAttempts] TINYINT NOT NULL
            CONSTRAINT [DF_DA_OtpAttempts] DEFAULT 0;
END
ELSE PRINT '[L3] DeliveryOtpAttempts already exists — skipping.';
GO

IF COL_LENGTH('dbo.DeliveryAssignments', 'DeliveryOtpLockedUntil') IS NULL
BEGIN
    PRINT '[L3] Adding DeliveryOtpLockedUntil...';
    ALTER TABLE [dbo].[DeliveryAssignments]
        ADD [DeliveryOtpLockedUntil] DATETIME2(0) NULL;
END
ELSE PRINT '[L3] DeliveryOtpLockedUntil already exists — skipping.';
GO

------------------------------------------------------------------------------
-- 2. SendOtp SP
------------------------------------------------------------------------------
PRINT '[L3] Refreshing usp_Dispatcher_Delivery_SendOtp...';
IF OBJECT_ID(N'[dbo].[usp_Dispatcher_Delivery_SendOtp]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_Dispatcher_Delivery_SendOtp];
GO

CREATE PROCEDURE [dbo].[usp_Dispatcher_Delivery_SendOtp]
    @AssignmentId INT,
    @DispatcherId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Status TINYINT, @OrderItemId INT, @OrderId INT, @OrderNumber NVARCHAR(50),
                @BuyerId INT, @BuyerName NVARCHAR(200), @BuyerMobile NVARCHAR(20), @ProductName NVARCHAR(300);

        SELECT @Status=da.[Status], @OrderItemId=da.[OrderItemId], @OrderId=o.[OrderId],
               @OrderNumber=o.[OrderNumber], @BuyerId=o.[UserId],
               @BuyerName=u.[FirstName]+N' '+ISNULL(u.[LastName],N''), @BuyerMobile=u.[Mobile],
               @ProductName=oi.[ProductName]
        FROM   [dbo].[DeliveryAssignments] da
        INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderItemId]=da.[OrderItemId]
        INNER JOIN [dbo].[Orders] o ON o.[OrderId]=oi.[OrderId]
        INNER JOIN [dbo].[Users] u ON u.[UserId]=o.[UserId]
        WHERE  da.[AssignmentId]=@AssignmentId AND da.[DispatcherId]=@DispatcherId;

        IF @Status IS NULL THROW 50430, N'Assignment not found or not owned by you.', 1;
        IF @Status <> 9   THROW 50431, N'OTP can only be sent for items that are Out for Delivery.', 1;

        DECLARE @Otp NVARCHAR(6) = RIGHT(N'000000'+CAST(ABS(CHECKSUM(NEWID()))%1000000 AS NVARCHAR(6)), 6);

        BEGIN TRANSACTION;
            UPDATE [dbo].[DeliveryAssignments]
            SET [DeliveryOtp]=@Otp, [DeliveryOtpSentAt]=GETUTCDATE(),
                [DeliveryOtpAttempts]=0, [DeliveryOtpLockedUntil]=NULL, [UpdatedAt]=GETUTCDATE()
            WHERE [AssignmentId]=@AssignmentId;

            INSERT INTO [dbo].[Notifications]
                ([UserId],[Title],[Body],[NotificationType],[EntityType],[EntityId],[Channel])
            VALUES
                (@BuyerId, N'Delivery OTP',
                 N'Your delivery OTP for order '+@OrderNumber+N' is '+@Otp+
                 N'. Share it with the delivery agent to receive "'+@ProductName+N'".',
                 2, N'Order', @OrderId, 1);
        COMMIT TRANSACTION;

        SELECT @Otp AS [Otp], @OrderNumber AS [OrderNumber],
               @BuyerName AS [BuyerName], @BuyerMobile AS [BuyerMobile];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

------------------------------------------------------------------------------
-- 3. VerifyOtp SP
------------------------------------------------------------------------------
PRINT '[L3] Refreshing usp_Dispatcher_Delivery_VerifyOtp...';
IF OBJECT_ID(N'[dbo].[usp_Dispatcher_Delivery_VerifyOtp]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_Dispatcher_Delivery_VerifyOtp];
GO

CREATE PROCEDURE [dbo].[usp_Dispatcher_Delivery_VerifyOtp]
    @AssignmentId INT, @DispatcherId INT, @Otp NVARCHAR(6),
    @ProofUrl NVARCHAR(500)=NULL, @GpsLat DECIMAL(9,6)=NULL, @GpsLng DECIMAL(9,6)=NULL,
    @CodCollected DECIMAL(18,2)=NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Status TINYINT, @StoredOtp NVARCHAR(6), @SentAt DATETIME2(0), @Attempts TINYINT,
                @LockedUntil DATETIME2(0), @OrderItemId INT, @OrderId INT, @OrderNumber NVARCHAR(50),
                @ProductName NVARCHAR(300), @AttemptNum TINYINT;

        SELECT @Status=da.[Status], @StoredOtp=da.[DeliveryOtp], @SentAt=da.[DeliveryOtpSentAt],
               @Attempts=da.[DeliveryOtpAttempts], @LockedUntil=da.[DeliveryOtpLockedUntil],
               @OrderItemId=da.[OrderItemId], @AttemptNum=da.[AttemptNumber],
               @OrderId=o.[OrderId], @OrderNumber=o.[OrderNumber], @ProductName=oi.[ProductName]
        FROM   [dbo].[DeliveryAssignments] da WITH (UPDLOCK, ROWLOCK)
        INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderItemId]=da.[OrderItemId]
        INNER JOIN [dbo].[Orders] o ON o.[OrderId]=oi.[OrderId]
        WHERE  da.[AssignmentId]=@AssignmentId AND da.[DispatcherId]=@DispatcherId;

        IF @Status IS NULL    THROW 50432, N'Assignment not found or not owned by you.', 1;
        IF @Status <> 9       THROW 50433, N'This item is not out for delivery.', 1;
        IF @StoredOtp IS NULL THROW 50434, N'No OTP has been sent. Tap "Send OTP" first.', 1;
        IF @LockedUntil IS NOT NULL AND @LockedUntil > GETUTCDATE()
            THROW 50436, N'Too many wrong attempts. Try again in a few minutes or call the buyer.', 1;
        IF DATEDIFF(MINUTE, @SentAt, GETUTCDATE()) >= 15
            THROW 50435, N'OTP expired. Send a fresh one.', 1;

        IF @StoredOtp <> @Otp
        BEGIN
            DECLARE @NewAttempts TINYINT = @Attempts + 1;
            UPDATE [dbo].[DeliveryAssignments]
            SET [DeliveryOtpAttempts]=@NewAttempts,
                [DeliveryOtpLockedUntil]=CASE WHEN @NewAttempts>=3 THEN DATEADD(MINUTE,5,GETUTCDATE()) ELSE [DeliveryOtpLockedUntil] END,
                [UpdatedAt]=GETUTCDATE()
            WHERE [AssignmentId]=@AssignmentId;

            INSERT INTO [dbo].[DeliveryAttempts]
                ([AssignmentId],[AttemptNumber],[Outcome],[Notes],[GpsLat],[GpsLng])
            VALUES (@AssignmentId,@AttemptNum,N'OTP_FAIL',
                    N'Wrong OTP entered (attempt '+CAST(@NewAttempts AS NVARCHAR(3))+N').',@GpsLat,@GpsLng);

            IF @NewAttempts>=3 THROW 50436, N'Too many wrong attempts. Locked for 5 minutes — call the buyer to confirm.', 1;
            ELSE               THROW 50437, N'Incorrect OTP. Please re-check with the buyer.', 1;
        END

        BEGIN TRANSACTION;
            UPDATE [dbo].[DeliveryAssignments]
            SET [Status]=5, [DeliveredAt]=GETUTCDATE(), [DeliveryProofUrl]=@ProofUrl,
                [DeliveryGpsLat]=@GpsLat, [DeliveryGpsLng]=@GpsLng, [CodCollected]=@CodCollected,
                [CodSettledAt]=CASE WHEN @CodCollected IS NOT NULL THEN GETUTCDATE() ELSE NULL END,
                [DeliveryOtp]=NULL, [UpdatedAt]=GETUTCDATE()
            WHERE [AssignmentId]=@AssignmentId;

            UPDATE [dbo].[OrderItems] SET [OrderStatus]=5, [UpdatedAt]=GETUTCDATE() WHERE [OrderItemId]=@OrderItemId;
            UPDATE [dbo].[Orders] SET [DeliveredAt]=COALESCE([DeliveredAt],GETUTCDATE()), [UpdatedAt]=GETUTCDATE() WHERE [OrderId]=@OrderId;
            DELETE FROM [dbo].[DispatcherCurrentPositions] WHERE [AssignmentId]=@AssignmentId;

            INSERT INTO [dbo].[DeliveryAttempts]
                ([AssignmentId],[AttemptNumber],[Outcome],[Notes],[GpsLat],[GpsLng])
            VALUES (@AssignmentId,@AttemptNum,N'DELIVERED',
                    CASE WHEN @CodCollected IS NOT NULL THEN N'Delivered. COD collected: '+CAST(@CodCollected AS NVARCHAR(20))
                         ELSE N'Delivered (prepaid).' END, @GpsLat,@GpsLng);

            INSERT INTO [dbo].[OrderTrackings]
                ([OrderId],[OrderItemId],[Status],[Note],[ChangedAt])
            VALUES (@OrderId,@OrderItemId,N'DELIVERED',
                    N'"'+@ProductName+N'" delivered to the buyer (OTP verified).', GETUTCDATE());
        COMMIT TRANSACTION;

        SELECT @AssignmentId AS [AssignmentId], @OrderItemId AS [OrderItemId],
               5 AS [Status], @OrderNumber AS [OrderNumber];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

PRINT '[L3] Done.';
GO
