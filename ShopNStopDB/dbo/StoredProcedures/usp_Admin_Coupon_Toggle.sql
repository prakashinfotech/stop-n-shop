CREATE PROCEDURE [dbo].[usp_Admin_Coupon_Toggle]
    @CouponId    INT,
    @IsActive    BIT,
    @AdminUserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Coupons] WHERE [CouponId] = @CouponId AND [IsDeleted] = 0)
            THROW 50082, N'Coupon not found.', 1;

        UPDATE c SET
            c.[IsActive]  = @IsActive,
            c.[UpdatedAt] = GETUTCDATE(),
            c.[UpdatedBy] = @AdminUserId
        FROM [dbo].[Coupons] c
        WHERE c.[CouponId] = @CouponId;

        -- Also flip the parent Offer so it doesn't leak through other surfaces.
        UPDATE o SET
            o.[IsActive]  = @IsActive,
            o.[UpdatedAt] = GETUTCDATE(),
            o.[UpdatedBy] = @AdminUserId
        FROM [dbo].[Offers] o
        INNER JOIN [dbo].[Coupons] c ON c.[OfferId] = o.[OfferId]
        WHERE c.[CouponId] = @CouponId;

        SELECT 1 AS [Success];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
