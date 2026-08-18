CREATE PROCEDURE [dbo].[usp_Seller_Settlement_GetById]
    @SettlementId INT,
    @SellerId     INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT [SettlementId], [SellerId], [PeriodStart], [PeriodEnd],
           [GrossSales], [CommissionAmount], [TdsAmount], [PenaltyAmount],
           [RefundAmount], [NetPayout], [Status], [PaidAt], [UtrNumber],
           [BankAccountId], [Notes], [CreatedAt]
    FROM   [dbo].[SellerSettlements]
    WHERE  [SettlementId] = @SettlementId AND [SellerId] = @SellerId AND [IsDeleted] = 0;

    SELECT [SettlementLineId], [SettlementId], [OrderItemId], [OrderId],
           [GrossAmount], [CommissionAmount], [TdsAmount], [PenaltyAmount], [NetAmount]
    FROM   [dbo].[SellerSettlementLines]
    WHERE  [SettlementId] = @SettlementId;
END;
GO
