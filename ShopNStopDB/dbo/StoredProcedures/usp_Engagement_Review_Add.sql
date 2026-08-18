CREATE PROCEDURE [dbo].[usp_Engagement_Review_Add]
    @UserId       INT,
    @ProductId    INT,
    @OrderItemId  INT,
    @Rating       TINYINT,
    @Title        NVARCHAR(200)  = NULL,
    @Body         NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- When OrderItemId is supplied, verify the user actually purchased and received this item.
        -- When NULL, accept the review as-is (open review flow). Reviews remain unapproved until moderation.
        IF @OrderItemId IS NOT NULL
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM [dbo].[OrderItems] oi
                INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
                WHERE oi.[OrderItemId] = @OrderItemId
                  AND o.[UserId]       = @UserId
                  AND oi.[ProductId]   = @ProductId
                  AND o.[OrderStatus]  = 5  -- Delivered
                  AND oi.[IsDeleted]   = 0
                  AND o.[IsDeleted]    = 0
            )
                THROW 50150, N'You can only review products from delivered orders.', 1;

            IF EXISTS (
                SELECT 1 FROM [dbo].[Reviews]
                WHERE [UserId] = @UserId AND [OrderItemId] = @OrderItemId AND [IsDeleted] = 0
            )
                THROW 50151, N'You have already reviewed this item.', 1;
        END
        ELSE
        BEGIN
            -- Open-review flow: one review per (user, product) when no order is attached.
            IF EXISTS (
                SELECT 1 FROM [dbo].[Reviews]
                WHERE [UserId] = @UserId
                  AND [ProductId] = @ProductId
                  AND [OrderItemId] IS NULL
                  AND [IsDeleted] = 0
            )
                THROW 50151, N'You have already reviewed this product.', 1;
        END

        INSERT INTO [dbo].[Reviews]
            ([UserId], [ProductId], [OrderItemId], [Rating], [Title], [Body],
             [IsApproved], [CreatedAt], [CreatedBy], [IsDeleted])
        VALUES
            (@UserId, @ProductId, @OrderItemId, @Rating, @Title, @Body,
             1, GETUTCDATE(), @UserId, 0);

        SELECT SCOPE_IDENTITY() AS [ReviewId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
