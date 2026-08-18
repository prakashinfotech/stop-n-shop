CREATE PROCEDURE [dbo].[usp_Seller_Settlement_List]
    @SellerId INT,
    @Page     INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    IF @Page     < 1 SET @Page = 1;
    IF @PageSize < 1 SET @PageSize = 20;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT COUNT(1) AS [TotalCount]
    FROM   [dbo].[SellerSettlements]
    WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0;

    SELECT [SettlementId], [SellerId], [PeriodStart], [PeriodEnd],
           [GrossSales], [CommissionAmount], [TdsAmount], [PenaltyAmount],
           [RefundAmount], [NetPayout], [Status], [PaidAt], [UtrNumber], [CreatedAt]
    FROM   [dbo].[SellerSettlements]
    WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0
    ORDER  BY [PeriodEnd] DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO
