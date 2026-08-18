-- Mark an order's payment as refunded. Does NOT call any payment gateway —
-- gateway interaction is the caller's responsibility; this SP records the
-- post-condition once the gateway confirms.
CREATE PROCEDURE [dbo].[usp_Admin_Order_ManualRefund]
    @OrderId      INT,
    @AdminUserId  INT,
    @RefundAmount DECIMAL(18,2),
    @Reason       NVARCHAR(500),
    @GatewayRef   NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @PaymentStatus TINYINT, @TotalAmount DECIMAL(18,2);
        SELECT @PaymentStatus = [PaymentStatus],
               @TotalAmount   = [TotalAmount]
        FROM   [dbo].[Orders]
        WHERE  [OrderId] = @OrderId AND [IsDeleted] = 0;

        IF @PaymentStatus IS NULL
            THROW 50160, N'Order not found.', 1;

        IF @PaymentStatus = 4
            THROW 50161, N'Order is already refunded.', 1;

        IF @PaymentStatus <> 2
            THROW 50162, N'Only paid orders can be refunded.', 1;

        IF @RefundAmount <= 0 OR @RefundAmount > @TotalAmount
            THROW 50163, N'Refund amount must be positive and not exceed order total.', 1;

        UPDATE [dbo].[Orders]
        SET    [PaymentStatus]          = 4,
               [PaymentGatewayResponse] = CONCAT(
                    N'{"refund":{"amount":', @RefundAmount,
                    N',"reason":"', REPLACE(ISNULL(@Reason, N''), N'"', N'\"'),
                    N'","gatewayRef":"', ISNULL(@GatewayRef, N''),
                    N'","adminUserId":', @AdminUserId,
                    N',"at":"', CONVERT(NVARCHAR(33), SYSUTCDATETIME(), 127), N'"}}'),
               [UpdatedAt]              = GETUTCDATE(),
               [UpdatedBy]              = @AdminUserId
        WHERE  [OrderId] = @OrderId;

        SELECT 1 AS [Success];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
