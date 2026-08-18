CREATE PROCEDURE [dbo].[usp_Seller_Settlement_Calculate]
    @SellerId     INT,
    @PeriodStart  DATE,
    @PeriodEnd    DATE,
    @CalculatedBy INT
AS
/*
  Builds a settlement for one seller covering all delivered order-items in [PeriodStart, PeriodEnd]
  that have not been settled previously (T+7 cohort enforced by caller via PeriodEnd <= today - 7).

  Per-line math:
    Gross       = OrderItems.TotalPrice
    Commission  = COALESCE(OrderItems.CommissionAmount, Gross * default_rate)
    TDS         = Commission * default_tds_rate
    Penalty     = 0 (extension hook for SLA misses)
    Net         = Gross - Commission - TDS - Penalty
*/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
        THROW 50090, N'Seller not found.', 1;

    DECLARE @DefaultCommissionRate DECIMAL(5,2) = 10.00;
    DECLARE @DefaultTdsRate        DECIMAL(5,2) = 1.00;

    SELECT TOP 1
           @DefaultCommissionRate = [CommissionRate],
           @DefaultTdsRate        = [TdsRate]
    FROM   [dbo].[CommissionPlans]
    WHERE  [IsDefault] = 1 AND [IsDeleted] = 0 AND [IsActive] = 1
       AND [EffectiveFrom] <= @PeriodEnd
       AND ([EffectiveTo] IS NULL OR [EffectiveTo] >= @PeriodStart);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Snapshot eligible lines into a temp table
        CREATE TABLE #Lines
        (
            [OrderItemId]      INT NOT NULL PRIMARY KEY,
            [OrderId]          INT NOT NULL,
            [GrossAmount]      DECIMAL(18,2) NOT NULL,
            [CommissionAmount] DECIMAL(18,2) NOT NULL,
            [TdsAmount]        DECIMAL(18,2) NOT NULL,
            [PenaltyAmount]    DECIMAL(18,2) NOT NULL,
            [NetAmount]        DECIMAL(18,2) NOT NULL
        );

        INSERT INTO #Lines ([OrderItemId], [OrderId], [GrossAmount], [CommissionAmount], [TdsAmount], [PenaltyAmount], [NetAmount])
        SELECT oi.[OrderItemId],
               oi.[OrderId],
               oi.[TotalPrice]                                                                 AS [GrossAmount],
               COALESCE(oi.[CommissionAmount], oi.[TotalPrice] * @DefaultCommissionRate / 100) AS [CommissionAmount],
               COALESCE(oi.[CommissionAmount], oi.[TotalPrice] * @DefaultCommissionRate / 100) * @DefaultTdsRate / 100 AS [TdsAmount],
               0                                                                               AS [PenaltyAmount],
               oi.[TotalPrice]
                 - COALESCE(oi.[CommissionAmount], oi.[TotalPrice] * @DefaultCommissionRate / 100)
                 - (COALESCE(oi.[CommissionAmount], oi.[TotalPrice] * @DefaultCommissionRate / 100) * @DefaultTdsRate / 100)
                                                                                              AS [NetAmount]
        FROM   [dbo].[OrderItems] oi
        INNER  JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
        LEFT   JOIN [dbo].[SellerSettlementLines] ssl ON ssl.[OrderItemId] = oi.[OrderItemId]
        WHERE  oi.[SellerId]     = @SellerId
           AND oi.[IsDeleted]    = 0
           AND oi.[IsReturned]   = 0
           AND o.[IsDeleted]     = 0
           AND o.[OrderStatus]   = 5  -- Delivered
           AND o.[PaymentStatus] = 2  -- Paid (don't pay sellers for COD orders that haven't cleared)
           AND CAST(o.[DeliveredAt] AS DATE) BETWEEN @PeriodStart AND @PeriodEnd
           AND ssl.[SettlementLineId] IS NULL;

        IF NOT EXISTS (SELECT 1 FROM #Lines)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT CAST(NULL AS INT) AS [SettlementId],
                   @SellerId         AS [SellerId],
                   @PeriodStart      AS [PeriodStart],
                   @PeriodEnd        AS [PeriodEnd],
                   CAST(0 AS DECIMAL(18,2)) AS [GrossSales],
                   CAST(0 AS DECIMAL(18,2)) AS [NetPayout],
                   0                 AS [LineCount];
            RETURN;
        END

        DECLARE @Gross   DECIMAL(18,2);
        DECLARE @Comm    DECIMAL(18,2);
        DECLARE @Tds     DECIMAL(18,2);
        DECLARE @Penalty DECIMAL(18,2);
        DECLARE @Net     DECIMAL(18,2);

        SELECT @Gross   = SUM([GrossAmount]),
               @Comm    = SUM([CommissionAmount]),
               @Tds     = SUM([TdsAmount]),
               @Penalty = SUM([PenaltyAmount]),
               @Net     = SUM([NetAmount])
        FROM   #Lines;

        DECLARE @PrimaryBankId INT;
        SELECT TOP 1 @PrimaryBankId = [BankAccountId]
        FROM   [dbo].[SellerBankAccounts]
        WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0
        ORDER  BY [IsPrimary] DESC, [CreatedAt] DESC;

        INSERT INTO [dbo].[SellerSettlements]
            ([SellerId], [PeriodStart], [PeriodEnd], [GrossSales], [CommissionAmount],
             [TdsAmount], [PenaltyAmount], [RefundAmount], [NetPayout], [Status],
             [BankAccountId], [CreatedBy], [UpdatedBy])
        VALUES
            (@SellerId, @PeriodStart, @PeriodEnd, @Gross, @Comm,
             @Tds, @Penalty, 0, @Net, 1,
             @PrimaryBankId, @CalculatedBy, @CalculatedBy);

        DECLARE @SettlementId INT = SCOPE_IDENTITY();

        INSERT INTO [dbo].[SellerSettlementLines]
            ([SettlementId], [OrderItemId], [OrderId], [GrossAmount], [CommissionAmount],
             [TdsAmount], [PenaltyAmount], [NetAmount])
        SELECT @SettlementId, [OrderItemId], [OrderId], [GrossAmount], [CommissionAmount],
               [TdsAmount], [PenaltyAmount], [NetAmount]
        FROM   #Lines;

        DROP TABLE #Lines;
        COMMIT TRANSACTION;

        SELECT [SettlementId], [SellerId], [PeriodStart], [PeriodEnd],
               [GrossSales], [CommissionAmount], [TdsAmount], [PenaltyAmount],
               [RefundAmount], [NetPayout], [Status], [CreatedAt]
        FROM   [dbo].[SellerSettlements]
        WHERE  [SettlementId] = @SettlementId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
