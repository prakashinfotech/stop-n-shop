/*
 * 2026-05-26 — Live-DB patch: refresh BankAccount_Add + Dashboard_GetAnalytics SPs
 *
 * Source SSDT files updated in:
 *   ShopNStopDB/dbo/StoredProcedures/usp_Seller_BankAccount_Add.sql
 *   ShopNStopDB/dbo/StoredProcedures/usp_Seller_Dashboard_GetAnalytics.sql
 *
 * Since the Docker DB doesn't run dacpac publish, this patch DROP+CREATEs both
 * SPs in-place so the running container picks them up. Idempotent.
 */

SET NOCOUNT ON;

IF OBJECT_ID(N'[dbo].[usp_Seller_BankAccount_Add]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_Seller_BankAccount_Add];
GO

CREATE PROCEDURE [dbo].[usp_Seller_BankAccount_Add]
    @SellerId           INT,
    @AccountHolderName  NVARCHAR(200),
    @BankName           NVARCHAR(100),
    @AccountNumber      NVARCHAR(50),
    @IfscCode           NVARCHAR(20),
    @BranchName         NVARCHAR(200) = NULL,
    @IsPrimary          BIT = 0,
    @CreatedBy          INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Mandatory-primary rule: every seller must have exactly one primary
        -- bank account so settlement payouts have an unambiguous destination.
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[SellerBankAccounts]
            WHERE [SellerId] = @SellerId AND [IsDeleted] = 0
        )
            SET @IsPrimary = 1;

        IF @IsPrimary = 1
            UPDATE [dbo].[SellerBankAccounts]
            SET    [IsPrimary] = 0,
                   [UpdatedAt] = GETUTCDATE(),
                   [UpdatedBy] = @CreatedBy
            WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0;

        INSERT INTO [dbo].[SellerBankAccounts]
            ([SellerId], [AccountHolderName], [BankName], [AccountNumber], [IfscCode], [BranchName],
             [IsPrimary], [IsVerified], [CreatedBy], [UpdatedBy])
        VALUES
            (@SellerId, @AccountHolderName, @BankName, @AccountNumber, @IfscCode, @BranchName,
             @IsPrimary, 0, @CreatedBy, @CreatedBy);

        DECLARE @NewId INT = SCOPE_IDENTITY();
        COMMIT TRANSACTION;

        SELECT [BankAccountId], [SellerId], [AccountHolderName], [BankName],
               [AccountNumber], [IfscCode], [BranchName], [IsPrimary], [IsVerified], [CreatedAt]
        FROM   [dbo].[SellerBankAccounts]
        WHERE  [BankAccountId] = @NewId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

IF OBJECT_ID(N'[dbo].[usp_Seller_Dashboard_GetAnalytics]', N'P') IS NOT NULL
    DROP PROCEDURE [dbo].[usp_Seller_Dashboard_GetAnalytics];
GO

CREATE PROCEDURE [dbo].[usp_Seller_Dashboard_GetAnalytics]
    @SellerId INT,
    @FromDate DATE = NULL,
    @ToDate   DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @FromDate = COALESCE(@FromDate, DATEADD(DAY, -29, CAST(GETUTCDATE() AS DATE)));
    SET @ToDate   = COALESCE(@ToDate,   CAST(GETUTCDATE() AS DATE));

    DECLARE @TotalRevenue DECIMAL(18,2) = 0;
    DECLARE @TotalOrders INT = 0;
    DECLARE @TotalUnitsSold INT = 0;
    DECLARE @AverageOrderValue DECIMAL(18,2) = 0;
    DECLARE @NewOrders INT = 0;
    DECLARE @ProcessingOrders INT = 0;
    DECLARE @ShippedOrders INT = 0;
    DECLARE @DeliveredOrders INT = 0;
    DECLARE @CancelledOrders INT = 0;

    -- Revenue / orders / units — restricted to Delivered + Paid line items so
    -- this number aligns with SellerSettlements gross sales exactly.
    SELECT @TotalRevenue   = ISNULL(SUM(oi.[TotalPrice]), 0),
           @TotalOrders    = COUNT(DISTINCT oi.[OrderId]),
           @TotalUnitsSold = ISNULL(SUM(oi.[Quantity]), 0)
    FROM   [dbo].[OrderItems] oi
    INNER  JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
    WHERE  oi.[SellerId]     = @SellerId
       AND oi.[IsDeleted]    = 0
       AND oi.[IsReturned]   = 0
       AND o.[IsDeleted]     = 0
       AND o.[OrderStatus]   = 5
       AND o.[PaymentStatus] = 2
       AND CAST(o.[CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate;

    SET @AverageOrderValue = CASE WHEN @TotalOrders > 0 THEN @TotalRevenue / @TotalOrders ELSE 0 END;

    -- Status breakdown (current state, ignoring date range)
    SELECT @NewOrders        = COUNT(DISTINCT oi.[OrderId]) FROM [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
        WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 1;

    SELECT @ProcessingOrders = COUNT(DISTINCT oi.[OrderId]) FROM [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
        WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 3;

    SELECT @ShippedOrders    = COUNT(DISTINCT oi.[OrderId]) FROM [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
        WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 4;

    SELECT @DeliveredOrders  = COUNT(DISTINCT oi.[OrderId]) FROM [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
        WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 5;

    SELECT @CancelledOrders  = COUNT(DISTINCT oi.[OrderId]) FROM [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Orders] o ON oi.[OrderId] = o.[OrderId]
        WHERE oi.[SellerId] = @SellerId AND oi.[IsDeleted] = 0 AND o.[OrderStatus] = 6;

    SELECT
        @FromDate           AS [FromDate],
        @ToDate             AS [ToDate],
        @TotalRevenue       AS [TotalRevenue],
        @TotalOrders        AS [TotalOrders],
        @TotalUnitsSold     AS [TotalUnitsSold],
        @AverageOrderValue  AS [AverageOrderValue],
        @NewOrders          AS [NewOrders],
        @ProcessingOrders   AS [ProcessingOrders],
        @ShippedOrders      AS [ShippedOrders],
        @DeliveredOrders    AS [DeliveredOrders],
        @CancelledOrders    AS [CancelledOrders];
END;
GO

PRINT '[patch] SPs refreshed.';
GO
