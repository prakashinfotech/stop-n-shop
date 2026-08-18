CREATE PROCEDURE [dbo].[usp_Seller_VendorAgreement_GetLatest]
    @SellerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 [AgreementId], [SellerId], [Version], [AcceptedAt], [DocumentUrl]
    FROM   [dbo].[VendorAgreements]
    WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0
    ORDER  BY [AcceptedAt] DESC;
END;
GO
