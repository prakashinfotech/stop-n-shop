-- Soft-delete a coupon and its parent Offer in one shot.
CREATE PROCEDURE [dbo].[usp_Admin_Coupon_Delete]
    @CouponId    INT,
    @AdminUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @OfferId INT;
        SELECT @OfferId = [OfferId]
        FROM   [dbo].[Coupons]
        WHERE  [CouponId] = @CouponId AND [IsDeleted] = 0;

        IF @OfferId IS NULL
            THROW 50095, N'Coupon not found.', 1;

        BEGIN TRANSACTION;

        UPDATE [dbo].[Coupons]
        SET    [IsDeleted] = 1,
               [IsActive]  = 0,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @AdminUserId
        WHERE  [CouponId]  = @CouponId;

        UPDATE [dbo].[Offers]
        SET    [IsDeleted] = 1,
               [IsActive]  = 0,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @AdminUserId
        WHERE  [OfferId]   = @OfferId;

        COMMIT TRANSACTION;

        SELECT 1 AS [Success];
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
