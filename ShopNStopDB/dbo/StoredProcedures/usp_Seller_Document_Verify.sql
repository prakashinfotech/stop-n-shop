CREATE PROCEDURE [dbo].[usp_Seller_Document_Verify]
    @DocumentId  INT,
    @VerifiedBy  INT,
    @IsVerified  BIT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[SellerDocuments] WHERE [DocumentId] = @DocumentId AND [IsDeleted] = 0)
        THROW 50091, N'Document not found.', 1;

    UPDATE [dbo].[SellerDocuments]
    SET    [IsVerified] = @IsVerified,
           [VerifiedBy] = @VerifiedBy,
           [UpdatedAt]  = GETUTCDATE(),
           [UpdatedBy]  = @VerifiedBy
    WHERE  [DocumentId] = @DocumentId;

    SELECT [DocumentId], [SellerId], [DocumentType], [DocumentUrl], [IsVerified], [VerifiedBy], [UpdatedAt]
    FROM   [dbo].[SellerDocuments]
    WHERE  [DocumentId] = @DocumentId;
END;
GO
