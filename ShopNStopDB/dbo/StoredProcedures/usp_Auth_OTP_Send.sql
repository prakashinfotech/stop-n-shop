CREATE PROCEDURE [dbo].[usp_Auth_OTP_Send]
    @UserId    INT,
    @OtpCode   NVARCHAR(10),
    @OtpType   TINYINT,        -- 1=Email, 2=Mobile
    @ExpiresAt DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50004, N'User not found.', 1;

        -- Invalidate any previous active OTPs for this user/type
        UPDATE [dbo].[OtpVerifications]
        SET    [IsDeleted] = 1
        WHERE  [UserId]    = @UserId
          AND  [OtpType]   = @OtpType
          AND  [IsUsed]    = 0
          AND  [IsDeleted] = 0;

        INSERT INTO [dbo].[OtpVerifications]
            ([UserId], [OtpCode], [OtpType], [ExpiresAt])
        VALUES
            (@UserId, @OtpCode, @OtpType, @ExpiresAt);

        SELECT SCOPE_IDENTITY() AS [OtpId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
