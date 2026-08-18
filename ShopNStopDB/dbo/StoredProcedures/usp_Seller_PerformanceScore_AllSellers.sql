CREATE PROCEDURE [dbo].[usp_Seller_PerformanceScore_AllSellers]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [SellerId]
    FROM   [dbo].[Sellers]
    WHERE  [IsDeleted] = 0 AND [ApprovalStatus] = 2;
END;
GO
