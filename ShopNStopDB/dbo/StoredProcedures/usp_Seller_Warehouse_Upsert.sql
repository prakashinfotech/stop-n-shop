CREATE PROCEDURE [dbo].[usp_Seller_Warehouse_Upsert]
    @SellerWarehouseId INT = NULL,
    @SellerId          INT,
    @Name              NVARCHAR(200),
    @ContactName       NVARCHAR(200) = NULL,
    @ContactPhone      NVARCHAR(20)  = NULL,
    @AddressLine1      NVARCHAR(300),
    @AddressLine2      NVARCHAR(300) = NULL,
    @City              NVARCHAR(100),
    @State             NVARCHAR(100),
    @Pincode           NVARCHAR(10),
    @IsPrimary         BIT = 0,
    @UpdatedBy         INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @IsPrimary = 1
            UPDATE [dbo].[SellerWarehouses]
            SET    [IsPrimary] = 0, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UpdatedBy
            WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0;

        IF @SellerWarehouseId IS NULL
        BEGIN
            INSERT INTO [dbo].[SellerWarehouses]
                ([SellerId], [Name], [ContactName], [ContactPhone], [AddressLine1], [AddressLine2],
                 [City], [State], [Pincode], [IsPrimary], [CreatedBy], [UpdatedBy])
            VALUES
                (@SellerId, @Name, @ContactName, @ContactPhone, @AddressLine1, @AddressLine2,
                 @City, @State, @Pincode, @IsPrimary, @UpdatedBy, @UpdatedBy);

            SET @SellerWarehouseId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE [dbo].[SellerWarehouses]
            SET    [Name] = @Name,
                   [ContactName] = @ContactName,
                   [ContactPhone] = @ContactPhone,
                   [AddressLine1] = @AddressLine1,
                   [AddressLine2] = @AddressLine2,
                   [City] = @City,
                   [State] = @State,
                   [Pincode] = @Pincode,
                   [IsPrimary] = @IsPrimary,
                   [UpdatedAt] = GETUTCDATE(),
                   [UpdatedBy] = @UpdatedBy
            WHERE  [SellerWarehouseId] = @SellerWarehouseId AND [SellerId] = @SellerId;
        END

        COMMIT TRANSACTION;

        SELECT [SellerWarehouseId], [SellerId], [Name], [AddressLine1], [City], [State], [Pincode], [IsPrimary]
        FROM   [dbo].[SellerWarehouses]
        WHERE  [SellerWarehouseId] = @SellerWarehouseId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
