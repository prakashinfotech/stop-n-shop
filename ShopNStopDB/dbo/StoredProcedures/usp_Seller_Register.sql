CREATE PROCEDURE [dbo].[usp_Seller_Register]
    @UserId       INT,
    @BusinessName NVARCHAR(300),
    @GstNumber    NVARCHAR(20)  = NULL,
    @PanNumber    NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50080, N'User not found.', 1;

        IF EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50081, N'Seller account already exists for this user.', 1;

        BEGIN TRANSACTION;

            -- Upgrade user role to Seller
            UPDATE [dbo].[Users]
            SET    [RoleId]    = 3,
                   [IsApproved] = 0,
                   [UpdatedAt] = GETUTCDATE(),
                   [UpdatedBy] = @UserId
            WHERE  [UserId] = @UserId;

            INSERT INTO [dbo].[Sellers]
                ([UserId], [BusinessName], [GstNumber], [PanNumber],
                 [ApprovalStatus], [CreatedBy], [UpdatedBy])
            VALUES
                (@UserId, @BusinessName, @GstNumber, @PanNumber,
                 1, @UserId, @UserId);

            DECLARE @NewSellerId INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            s.[SellerId], s.[UserId], s.[BusinessName], s.[ApprovalStatus],
            s.[GstNumber], s.[PanNumber], s.[CommissionRate]
        FROM [dbo].[Sellers] s
        WHERE s.[SellerId] = @NewSellerId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
