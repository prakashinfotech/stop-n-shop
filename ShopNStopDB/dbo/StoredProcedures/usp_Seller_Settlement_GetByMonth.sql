CREATE PROCEDURE [dbo].[usp_Seller_Settlement_GetByMonth]
    @SellerId INT,
    @Year     INT,
    @Month    INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Start DATE = DATEFROMPARTS(@Year, @Month, 1);
    DECLARE @End   DATE = EOMONTH(@Start);

    SELECT [SettlementId], [SellerId], [PeriodStart], [PeriodEnd],
           [GrossSales], [CommissionAmount], [TdsAmount], [PenaltyAmount],
           [RefundAmount], [NetPayout], [Status], [PaidAt], [UtrNumber],
           [BankAccountId], [Notes], [CreatedAt]
    FROM   [dbo].[SellerSettlements]
    WHERE  [SellerId] = @SellerId
       AND [IsDeleted] = 0
       AND [PeriodEnd] BETWEEN @Start AND @End
    ORDER  BY [PeriodEnd] DESC;
END;
GO
