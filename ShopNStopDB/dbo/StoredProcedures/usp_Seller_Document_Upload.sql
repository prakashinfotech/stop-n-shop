CREATE PROCEDURE [dbo].[usp_Seller_Document_Upload]
    @SellerId      INT,
    @DocumentType  TINYINT,
    @DocumentUrl   NVARCHAR(500),
    @UploadedBy    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
        THROW 50090, N'Seller not found.', 1;

    INSERT INTO [dbo].[SellerDocuments]
        ([SellerId], [DocumentType], [DocumentUrl], [IsVerified], [CreatedBy], [UpdatedBy])
    VALUES
        (@SellerId, @DocumentType, @DocumentUrl, 0, @UploadedBy, @UploadedBy);

    SELECT [DocumentId], [SellerId], [DocumentType], [DocumentUrl], [IsVerified], [CreatedAt]
    FROM   [dbo].[SellerDocuments]
    WHERE  [DocumentId] = SCOPE_IDENTITY();
END;
GO
