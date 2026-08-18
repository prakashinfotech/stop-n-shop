CREATE PROCEDURE [dbo].[usp_Seller_UpdateProfile]
    @SellerId       INT,
    @BusinessName   NVARCHAR(200),
    @GstNumber      NVARCHAR(20)   = NULL,
    @PanNumber      NVARCHAR(20)   = NULL,
    @BankName       NVARCHAR(100)  = NULL,
    @BankIfscCode   NVARCHAR(20)   = NULL,
    @BankAccountNumber NVARCHAR(50)   = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
            THROW 50095, N'Seller not found.', 1;

        UPDATE [dbo].[Sellers]
        SET    [BusinessName]  = @BusinessName,
               [GstNumber]     = @GstNumber,
               [PanNumber]     = @PanNumber,
               [BankName]      = @BankName,
               [BankIfscCode]  = @BankIfscCode,
               [BankAccountNumber] = @BankAccountNumber,
               [UpdatedAt]     = GETUTCDATE(),
               [UpdatedBy]     = @UpdatedBy
        WHERE  [SellerId] = @SellerId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
