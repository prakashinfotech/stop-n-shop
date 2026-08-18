CREATE PROCEDURE [dbo].[sp_SellerSignup]
    @Email        NVARCHAR(256),
    @PhoneNumber  NVARCHAR(15),
    @PasswordHash NVARCHAR(500),
    @SellerId     INT          OUTPUT,
    @ErrorCode    NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @SellerId  = 0;
    SET @ErrorCode = NULL;

    BEGIN TRY
        -- Duplicate email check
        IF EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [Email] = @Email AND [IsDeleted] = 0)
        BEGIN
            SET @ErrorCode = 'EMAIL_EXISTS';
            RETURN;
        END;

        BEGIN TRANSACTION;

            DECLARE @NewUserId INT;

            INSERT INTO [dbo].[Users]
                ([Email], [PasswordHash], [Mobile], [RoleId], [IsApproved], [ReferralCode])
            VALUES
                (@Email, @PasswordHash, @PhoneNumber, 3, 0,
                 UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''), 8)));

            SET @NewUserId = SCOPE_IDENTITY();

            INSERT INTO [dbo].[Sellers]
                ([UserId], [BusinessName], [ApprovalStatus], [CreatedBy], [UpdatedBy])
            VALUES
                (@NewUserId, N'', 1, @NewUserId, @NewUserId);

            SET @SellerId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
