CREATE PROCEDURE [dbo].[usp_Seller_Onboarding_AdvanceStage]
    @SellerId    INT,
    @Stage       NVARCHAR(50),     -- 'business', 'bank', 'pickup', 'documents', 'agreement', 'complete'
    @CompletedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
        THROW 50090, N'Seller not found.', 1;

    UPDATE [dbo].[Sellers]
    SET    [OnboardingCompleted] = CASE WHEN @Stage = N'complete' THEN 1 ELSE [OnboardingCompleted] END,
           [UpdatedAt]           = GETUTCDATE(),
           [UpdatedBy]           = @CompletedBy
    WHERE  [SellerId] = @SellerId;

    SELECT [SellerId],
           [OnboardingCompleted],
           [ApprovalStatus],
           @Stage AS [Stage]
    FROM   [dbo].[Sellers]
    WHERE  [SellerId] = @SellerId;
END;
GO
