CREATE PROCEDURE [dbo].[usp_Commerce_Wishlist_Add]
    @UserId    INT,
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50050, N'Product not found.', 1;

        IF EXISTS (SELECT 1 FROM [dbo].[Wishlist] WHERE [UserId] = @UserId AND [ProductId] = @ProductId AND [IsDeleted] = 0)
        BEGIN
            SELECT 1 AS [Success], N'Already in wishlist' AS [Message];
            RETURN;
        END;

        INSERT INTO [dbo].[Wishlist]
            ([UserId], [ProductId], [CreatedBy], [UpdatedBy])
        VALUES
            (@UserId, @ProductId, @UserId, @UserId);

        SELECT 1 AS [Success], N'Added to wishlist' AS [Message];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
