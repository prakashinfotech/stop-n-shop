CREATE PROCEDURE [dbo].[usp_Seller_VendorAgreement_Accept]
    @SellerId          INT,
    @Version           NVARCHAR(20),
    @AcceptedIp        NVARCHAR(45)  = NULL,
    @AcceptedUserAgent NVARCHAR(500) = NULL,
    @DocumentUrl       NVARCHAR(500) = NULL,
    @AcceptedBy        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
        THROW 50090, N'Seller not found.', 1;

    INSERT INTO [dbo].[VendorAgreements]
        ([SellerId], [Version], [AcceptedIp], [AcceptedUserAgent], [DocumentUrl], [CreatedBy])
    VALUES
        (@SellerId, @Version, @AcceptedIp, @AcceptedUserAgent, @DocumentUrl, @AcceptedBy);

    SELECT [AgreementId], [SellerId], [Version], [AcceptedAt], [DocumentUrl]
    FROM   [dbo].[VendorAgreements]
    WHERE  [AgreementId] = SCOPE_IDENTITY();
END;
GO
