CREATE PROCEDURE [dbo].[usp_Auth_OTP_Verify]
    @UserId  INT,
    @OtpCode NVARCHAR(10),
    @OtpType TINYINT        -- 1=Email, 2=Mobile
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @OtpId       INT;
        DECLARE @ExpiresAt   DATETIME2(0);
        DECLARE @IsUsed      BIT;
        DECLARE @AttemptCount TINYINT;

        SELECT
            @OtpId        = [OtpId],
            @ExpiresAt    = [ExpiresAt],
            @IsUsed       = [IsUsed],
            @AttemptCount = [AttemptCount]
        FROM [dbo].[OtpVerifications]
        WHERE [UserId]    = @UserId
          AND [OtpType]   = @OtpType
          AND [OtpCode]   = @OtpCode
          AND [IsDeleted] = 0
        ORDER BY [CreatedAt] DESC;

        IF @OtpId IS NULL
            THROW 50005, N'Invalid OTP code.', 1;

        IF @IsUsed = 1
            THROW 50006, N'OTP has already been used.', 1;

        IF @ExpiresAt < GETUTCDATE()
        BEGIN
            UPDATE [dbo].[OtpVerifications] SET [IsDeleted] = 1 WHERE [OtpId] = @OtpId;
            THROW 50007, N'OTP has expired.', 1;
        END;

        IF @AttemptCount >= 5
        BEGIN
            UPDATE [dbo].[OtpVerifications] SET [IsDeleted] = 1 WHERE [OtpId] = @OtpId;
            THROW 50008, N'Maximum OTP attempts exceeded. Please request a new OTP.', 1;
        END;

        BEGIN TRANSACTION;

            UPDATE [dbo].[OtpVerifications]
            SET    [IsUsed]       = 1,
                   [AttemptCount] = [AttemptCount] + 1
            WHERE  [OtpId] = @OtpId;

            -- Mark user email/mobile as verified
            IF @OtpType = 1
                UPDATE [dbo].[Users] SET [IsEmailVerified] = 1, [UpdatedAt] = GETUTCDATE() WHERE [UserId] = @UserId;
            ELSE IF @OtpType = 2
                UPDATE [dbo].[Users] SET [IsMobileVerified] = 1, [UpdatedAt] = GETUTCDATE() WHERE [UserId] = @UserId;

        COMMIT TRANSACTION;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
