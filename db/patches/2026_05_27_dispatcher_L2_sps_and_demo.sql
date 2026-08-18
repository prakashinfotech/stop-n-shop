/*
 * 2026-05-27 — Dispatcher L2: 6 SPs + demo dispatcher user
 *
 * This patch:
 *   1. DROP+CREATE the 6 SPs for L2 (Register, GetProfile, Pickup_GetQueue,
 *      Pickup_Claim, Pickup_Confirm, Active_GetAll)
 *   2. Seeds one demo dispatcher account so L2 can be tested end-to-end
 *      without an admin UI for onboarding (that's L7).
 *
 * Demo dispatcher credentials:
 *   Email:    dispatch@stopnshop.com
 *   Password: Dispatch@2026   (PBKDF2-SHA256 hash pre-baked into the patch)
 *   Role:     Dispatcher (RoleId 4)
 *   Code:     DLY-001
 *   Assigned: Mumbai DC (WH-MUM-01) and Bengaluru DC (WH-BLR-01)
 *
 * Idempotent: user MERGE-d on Email, dispatcher MERGE-d on UserId, warehouse
 * assignments MERGE-d on the composite PK.
 *
 * Apply:
 *   docker cp db/patches/2026_05_27_dispatcher_L2_sps_and_demo.sql stopnshop-db:/tmp/l2.sql
 *   docker exec -i stopnshop-db /opt/mssql-tools18/bin/sqlcmd \
 *     -S localhost -U sa -P "$SA_PASSWORD" -C -d ShopNShop_db -b -I -i /tmp/l2.sql
 */

SET NOCOUNT ON;
SET XACT_ABORT ON;

------------------------------------------------------------------------------
-- 1. SPs (drop + recreate from the SSDT source bodies)
------------------------------------------------------------------------------
PRINT '[L2] Refreshing usp_Dispatcher_Register...';
IF OBJECT_ID(N'[dbo].[usp_Dispatcher_Register]', N'P') IS NOT NULL DROP PROCEDURE [dbo].[usp_Dispatcher_Register];
GO
CREATE PROCEDURE [dbo].[usp_Dispatcher_Register]
    @UserId           INT,
    @EmployeeCode     NVARCHAR(20),
    @VehicleNumber    NVARCHAR(20)   = NULL,
    @VehicleType      NVARCHAR(20)   = NULL,
    @LicenseNumber    NVARCHAR(30)   = NULL,
    @BaseWarehouseId  INT            = NULL,
    @WarehouseIdsCsv  NVARCHAR(MAX)  = NULL,
    @CreatedBy        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] u WHERE u.[UserId] = @UserId AND u.[IsDeleted] = 0 AND u.[RoleId] = 4)
            THROW 50400, N'User not found or not a Dispatcher.', 1;
        IF EXISTS (SELECT 1 FROM [dbo].[Dispatchers] WHERE [EmployeeCode] = @EmployeeCode AND [IsDeleted] = 0 AND [UserId] <> @UserId)
            THROW 50401, N'EmployeeCode already in use by another dispatcher.', 1;

        BEGIN TRANSACTION;
            DECLARE @DispatcherId INT;
            SELECT @DispatcherId = [DispatcherId] FROM [dbo].[Dispatchers] WHERE [UserId] = @UserId AND [IsDeleted] = 0;

            IF @DispatcherId IS NULL
            BEGIN
                INSERT INTO [dbo].[Dispatchers] ([UserId], [EmployeeCode], [VehicleNumber], [VehicleType], [LicenseNumber], [BaseWarehouseId], [CreatedBy], [UpdatedBy])
                VALUES (@UserId, @EmployeeCode, @VehicleNumber, @VehicleType, @LicenseNumber, @BaseWarehouseId, @CreatedBy, @CreatedBy);
                SET @DispatcherId = SCOPE_IDENTITY();
            END
            ELSE
                UPDATE [dbo].[Dispatchers]
                SET [EmployeeCode] = @EmployeeCode, [VehicleNumber] = @VehicleNumber, [VehicleType] = @VehicleType,
                    [LicenseNumber] = @LicenseNumber, [BaseWarehouseId] = @BaseWarehouseId,
                    [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @CreatedBy
                WHERE [DispatcherId] = @DispatcherId;

            IF @WarehouseIdsCsv IS NOT NULL
            BEGIN
                DELETE FROM [dbo].[DispatcherWarehouseAssignments] WHERE [DispatcherId] = @DispatcherId;
                INSERT INTO [dbo].[DispatcherWarehouseAssignments] ([DispatcherId], [WarehouseId], [AssignedBy])
                SELECT @DispatcherId, CAST(LTRIM(RTRIM(value)) AS INT), @CreatedBy
                FROM STRING_SPLIT(@WarehouseIdsCsv, ',')
                WHERE LTRIM(RTRIM(value)) <> N''
                  AND EXISTS (SELECT 1 FROM [dbo].[Warehouses] w WHERE w.[WarehouseId] = CAST(LTRIM(RTRIM(value)) AS INT) AND w.[IsDeleted] = 0);
            END
        COMMIT TRANSACTION;

        SELECT [DispatcherId], [UserId], [EmployeeCode], [VehicleNumber], [VehicleType], [LicenseNumber], [BaseWarehouseId], [CreatedAt]
        FROM [dbo].[Dispatchers] WHERE [DispatcherId] = @DispatcherId;
    END TRY
    BEGIN CATCH IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; THROW; END CATCH;
END;
GO

PRINT '[L2] Refreshing usp_Dispatcher_GetProfile...';
IF OBJECT_ID(N'[dbo].[usp_Dispatcher_GetProfile]', N'P') IS NOT NULL DROP PROCEDURE [dbo].[usp_Dispatcher_GetProfile];
GO
CREATE PROCEDURE [dbo].[usp_Dispatcher_GetProfile]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        d.[DispatcherId], d.[UserId], d.[EmployeeCode], d.[VehicleNumber], d.[VehicleType],
        d.[LicenseNumber], d.[BaseWarehouseId], wb.[Name] AS [BaseWarehouseName],
        u.[FirstName], u.[LastName], u.[Email], u.[Mobile], d.[JoinedAt], d.[IsActive],
        STUFF((
            SELECT N', ' + w.[Code] + N' — ' + w.[Name]
            FROM [dbo].[DispatcherWarehouseAssignments] dwa
            INNER JOIN [dbo].[Warehouses] w ON w.[WarehouseId] = dwa.[WarehouseId]
            WHERE dwa.[DispatcherId] = d.[DispatcherId] AND w.[IsDeleted] = 0
            ORDER BY w.[Name] FOR XML PATH(''), TYPE
        ).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'') AS [AssignedWarehousesLabel]
    FROM [dbo].[Dispatchers] d
    INNER JOIN [dbo].[Users] u ON u.[UserId] = d.[UserId]
    LEFT JOIN [dbo].[Warehouses] wb ON wb.[WarehouseId] = d.[BaseWarehouseId]
    WHERE d.[UserId] = @UserId AND d.[IsDeleted] = 0;
END;
GO

PRINT '[L2] Refreshing usp_Dispatcher_Pickup_GetQueue...';
IF OBJECT_ID(N'[dbo].[usp_Dispatcher_Pickup_GetQueue]', N'P') IS NOT NULL DROP PROCEDURE [dbo].[usp_Dispatcher_Pickup_GetQueue];
GO
CREATE PROCEDURE [dbo].[usp_Dispatcher_Pickup_GetQueue]
    @DispatcherId INT,
    @Page         INT = 1,
    @PageSize     INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @PageSize;
    ;WITH MyWarehouses AS (
        SELECT [WarehouseId] FROM [dbo].[DispatcherWarehouseAssignments] WHERE [DispatcherId] = @DispatcherId
    ),
    VariantWarehouse AS (
        SELECT s.[VariantId], s.[WarehouseId],
               ROW_NUMBER() OVER (PARTITION BY s.[VariantId] ORDER BY s.[OnHand] DESC, s.[WarehouseId]) AS rn
        FROM [dbo].[Stock] s
        INNER JOIN MyWarehouses mw ON mw.[WarehouseId] = s.[WarehouseId]
    ),
    LatestAssignment AS (
        SELECT da.[OrderItemId], da.[AssignmentId], da.[DispatcherId], da.[Status],
               ROW_NUMBER() OVER (PARTITION BY da.[OrderItemId] ORDER BY da.[AssignedAt] DESC) AS rn
        FROM [dbo].[DeliveryAssignments] da
    )
    SELECT
        oi.[OrderItemId], oi.[OrderId], o.[OrderNumber], oi.[ProductName], oi.[VariantSnapshot],
        oi.[Quantity], oi.[TotalPrice], oi.[OrderStatus], oi.[CreatedAt] AS [OrderItemCreatedAt],
        vw.[WarehouseId], w.[Code] AS [WarehouseCode], w.[Name] AS [WarehouseName], w.[City] AS [WarehouseCity],
        o.[PaymentMode], o.[PaymentStatus],
        CASE WHEN o.[PaymentMode] = 1 AND o.[PaymentStatus] <> 2 THEN oi.[TotalPrice] ELSE NULL END AS [CodAmount],
        u.[FirstName] + N' ' + ISNULL(u.[LastName], N'') AS [BuyerName],
        u.[Mobile] AS [BuyerMobile],
        ua.[AddressLine1] AS [BuyerAddressLine1], ua.[City] AS [BuyerCity],
        ua.[State] AS [BuyerState], ua.[PinCode] AS [BuyerPincode],
        la.[AssignmentId], la.[Status] AS [AssignmentStatus],
        COUNT(*) OVER () AS [TotalCount]
    FROM [dbo].[OrderItems] oi
    INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
    INNER JOIN [dbo].[Users] u ON u.[UserId] = o.[UserId]
    LEFT JOIN [dbo].[UserAddresses] ua ON ua.[AddressId] = o.[ShippingAddressId]
    INNER JOIN VariantWarehouse vw ON vw.[VariantId] = oi.[VariantId] AND vw.rn = 1
    INNER JOIN [dbo].[Warehouses] w ON w.[WarehouseId] = vw.[WarehouseId]
    LEFT JOIN LatestAssignment la ON la.[OrderItemId] = oi.[OrderItemId] AND la.rn = 1
    WHERE oi.[IsDeleted] = 0 AND o.[IsDeleted] = 0
      AND ((oi.[OrderStatus] = 3 AND la.[AssignmentId] IS NULL)
           OR (oi.[OrderStatus] = 10 AND la.[DispatcherId] = @DispatcherId))
    ORDER BY
        CASE WHEN la.[DispatcherId] = @DispatcherId THEN 0 ELSE 1 END,
        oi.[CreatedAt] ASC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

PRINT '[L2] Refreshing usp_Dispatcher_Pickup_Claim...';
IF OBJECT_ID(N'[dbo].[usp_Dispatcher_Pickup_Claim]', N'P') IS NOT NULL DROP PROCEDURE [dbo].[usp_Dispatcher_Pickup_Claim];
GO
CREATE PROCEDURE [dbo].[usp_Dispatcher_Pickup_Claim]
    @OrderItemId  INT,
    @DispatcherId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        DECLARE @CurrentStatus TINYINT, @VariantId INT, @OrderId INT, @OrderNumber NVARCHAR(50),
                @ProductName NVARCHAR(300), @WarehouseId INT, @PaymentMode TINYINT, @PaymentStatus TINYINT, @TotalPrice DECIMAL(18,2);

        SELECT @CurrentStatus = oi.[OrderStatus], @VariantId = oi.[VariantId], @OrderId = oi.[OrderId],
               @OrderNumber = o.[OrderNumber], @ProductName = oi.[ProductName],
               @PaymentMode = o.[PaymentMode], @PaymentStatus = o.[PaymentStatus], @TotalPrice = oi.[TotalPrice]
        FROM [dbo].[OrderItems] oi WITH (UPDLOCK, ROWLOCK)
        INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
        WHERE oi.[OrderItemId] = @OrderItemId AND oi.[IsDeleted] = 0;

        IF @CurrentStatus IS NULL THROW 50410, N'Order item not found.', 1;
        IF @CurrentStatus <> 3   THROW 50411, N'Only Packed items can be picked up.', 1;

        SELECT TOP 1 @WarehouseId = s.[WarehouseId]
        FROM [dbo].[Stock] s
        INNER JOIN [dbo].[DispatcherWarehouseAssignments] dwa
            ON dwa.[WarehouseId] = s.[WarehouseId] AND dwa.[DispatcherId] = @DispatcherId
        WHERE s.[VariantId] = @VariantId
        ORDER BY s.[OnHand] DESC, s.[WarehouseId];

        IF @WarehouseId IS NULL THROW 50412, N'You are not assigned to this item''s warehouse.', 1;

        DECLARE @CodAmount DECIMAL(18,2) = CASE WHEN @PaymentMode = 1 AND @PaymentStatus <> 2 THEN @TotalPrice ELSE NULL END;

        BEGIN TRANSACTION;
            INSERT INTO [dbo].[DeliveryAssignments] ([OrderItemId], [DispatcherId], [WarehouseId], [Status], [PickedUpAt], [CodAmount])
            VALUES (@OrderItemId, @DispatcherId, @WarehouseId, 10, GETUTCDATE(), @CodAmount);
            DECLARE @AssignmentId INT = SCOPE_IDENTITY();

            UPDATE [dbo].[OrderItems] SET [OrderStatus] = 10, [UpdatedAt] = GETUTCDATE() WHERE [OrderItemId] = @OrderItemId;

            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [OrderItemId], [Status], [Note], [ChangedAt])
            VALUES (@OrderId, @OrderItemId, N'PICKED_UP',
                    N'"' + @ProductName + N'" picked up by dispatcher at the warehouse.', GETUTCDATE());
        COMMIT TRANSACTION;

        SELECT @AssignmentId AS [AssignmentId], @OrderItemId AS [OrderItemId], 10 AS [OrderStatus],
               @OrderNumber AS [OrderNumber], @WarehouseId AS [WarehouseId];
    END TRY
    BEGIN CATCH IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; THROW; END CATCH;
END;
GO

PRINT '[L2] Refreshing usp_Dispatcher_Pickup_Confirm...';
IF OBJECT_ID(N'[dbo].[usp_Dispatcher_Pickup_Confirm]', N'P') IS NOT NULL DROP PROCEDURE [dbo].[usp_Dispatcher_Pickup_Confirm];
GO
CREATE PROCEDURE [dbo].[usp_Dispatcher_Pickup_Confirm]
    @DispatcherId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @Affected TABLE (AssignmentId INT, OrderItemId INT, OrderId INT, ProductName NVARCHAR(300));

            INSERT INTO @Affected (AssignmentId, OrderItemId, OrderId, ProductName)
            SELECT da.[AssignmentId], oi.[OrderItemId], oi.[OrderId], oi.[ProductName]
            FROM [dbo].[DeliveryAssignments] da
            INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderItemId] = da.[OrderItemId]
            WHERE da.[DispatcherId] = @DispatcherId AND da.[Status] = 10
              AND oi.[OrderStatus] = 10 AND oi.[IsDeleted] = 0;

            DECLARE @Count INT = (SELECT COUNT(*) FROM @Affected);
            IF @Count = 0 BEGIN ROLLBACK TRANSACTION; SELECT 0 AS [Confirmed]; RETURN; END

            UPDATE da SET da.[Status] = 4, da.[UpdatedAt] = GETUTCDATE()
            FROM [dbo].[DeliveryAssignments] da INNER JOIN @Affected a ON a.AssignmentId = da.[AssignmentId];

            UPDATE oi SET oi.[OrderStatus] = 4, oi.[UpdatedAt] = GETUTCDATE()
            FROM [dbo].[OrderItems] oi INNER JOIN @Affected a ON a.OrderItemId = oi.[OrderItemId];

            INSERT INTO [dbo].[OrderTrackings] ([OrderId], [OrderItemId], [Status], [Note])
            SELECT a.OrderId, a.OrderItemId, N'DISPATCHED',
                   N'"' + a.ProductName + N'" left the warehouse and is in transit.'
            FROM @Affected a;
        COMMIT TRANSACTION;
        SELECT @Count AS [Confirmed];
    END TRY
    BEGIN CATCH IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; THROW; END CATCH;
END;
GO

PRINT '[L2] Refreshing usp_Dispatcher_Active_GetAll...';
IF OBJECT_ID(N'[dbo].[usp_Dispatcher_Active_GetAll]', N'P') IS NOT NULL DROP PROCEDURE [dbo].[usp_Dispatcher_Active_GetAll];
GO
CREATE PROCEDURE [dbo].[usp_Dispatcher_Active_GetAll]
    @DispatcherId INT,
    @Page         INT = 1,
    @PageSize     INT = 50
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Offset INT = (@Page - 1) * @PageSize;
    SELECT
        da.[AssignmentId], da.[Status] AS [AssignmentStatus],
        da.[AssignedAt], da.[PickedUpAt], da.[OutForDeliveryAt],
        da.[AttemptNumber], da.[CodAmount],
        oi.[OrderItemId], oi.[OrderId], o.[OrderNumber],
        oi.[ProductName], oi.[VariantSnapshot], oi.[Quantity], oi.[TotalPrice], oi.[OrderStatus],
        w.[Code] AS [WarehouseCode], w.[Name] AS [WarehouseName],
        u.[FirstName] + N' ' + ISNULL(u.[LastName], N'') AS [BuyerName],
        u.[Mobile] AS [BuyerMobile],
        ua.[AddressLine1] AS [BuyerAddressLine1], ua.[City] AS [BuyerCity],
        ua.[State] AS [BuyerState], ua.[PinCode] AS [BuyerPincode],
        o.[PaymentMode], o.[PaymentStatus],
        COUNT(*) OVER() AS [TotalCount]
    FROM [dbo].[DeliveryAssignments] da
    INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderItemId] = da.[OrderItemId]
    INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
    INNER JOIN [dbo].[Users] u ON u.[UserId] = o.[UserId]
    LEFT JOIN [dbo].[UserAddresses] ua ON ua.[AddressId] = o.[ShippingAddressId]
    INNER JOIN [dbo].[Warehouses] w ON w.[WarehouseId] = da.[WarehouseId]
    WHERE da.[DispatcherId] = @DispatcherId
      AND da.[Status] IN (10, 4, 9, 11) AND oi.[IsDeleted] = 0
    ORDER BY
        CASE da.[Status] WHEN 9 THEN 0 WHEN 11 THEN 1 WHEN 4 THEN 2 ELSE 3 END,
        da.[AssignedAt] DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

------------------------------------------------------------------------------
-- 2. Demo dispatcher seed
--    User: dispatch@stopnshop.com  / Dispatch@2026
--    Pre-baked PBKDF2-SHA256 hash (100K iters, 32-byte) — matches AuthService.HashPassword
------------------------------------------------------------------------------
PRINT '[L2] Seeding demo dispatcher account...';

-- ReferralCode is UNIQUE — multiple NULLs collide on this column. Provide a unique value.
MERGE [dbo].[Users] AS tgt
USING (VALUES
    (N'dispatch@stopnshop.com', N'9000000001',
     N'zJdE6KH86PzMkNFDTXMtLw==:t+v+qaKfU90WSGL72hQuGM5deaNbwIH9KtvuZ9UzX4I=',
     4, N'Demo', N'Dispatcher', 1, N'DEMODLY01')
) AS src ([Email], [Mobile], [PasswordHash], [RoleId], [FirstName], [LastName], [IsEmailVerified], [ReferralCode])
ON tgt.[Email] = src.[Email]
WHEN MATCHED THEN UPDATE SET
    tgt.[RoleId]       = src.[RoleId],
    tgt.[PasswordHash] = src.[PasswordHash],
    tgt.[FirstName]    = src.[FirstName],
    tgt.[LastName]     = src.[LastName],
    tgt.[UpdatedAt]    = GETUTCDATE()
WHEN NOT MATCHED THEN INSERT
    ([Email], [Mobile], [PasswordHash], [RoleId], [FirstName], [LastName],
     [IsEmailVerified], [IsMobileVerified], [IsApproved], [ReferralCode])
VALUES
    (src.[Email], src.[Mobile], src.[PasswordHash], src.[RoleId], src.[FirstName], src.[LastName],
     src.[IsEmailVerified], 0, 1, src.[ReferralCode]);

DECLARE @DispatchUserId INT = (SELECT UserId FROM [dbo].[Users] WHERE Email = N'dispatch@stopnshop.com');
DECLARE @AdminUserId    INT = 1;
DECLARE @MumbaiWhId     INT = (SELECT WarehouseId FROM [dbo].[Warehouses] WHERE Code = N'WH-MUM-01');
DECLARE @BlrWhId        INT = (SELECT WarehouseId FROM [dbo].[Warehouses] WHERE Code = N'WH-BLR-01');
DECLARE @Csv NVARCHAR(50) = CAST(@MumbaiWhId AS NVARCHAR) + N',' + CAST(@BlrWhId AS NVARCHAR);

EXEC [dbo].[usp_Dispatcher_Register]
     @UserId          = @DispatchUserId,
     @EmployeeCode    = N'DLY-001',
     @VehicleNumber   = N'MH-12-AB-1234',
     @VehicleType     = N'bike',
     @LicenseNumber   = N'DL-MH-DEMO-001',
     @BaseWarehouseId = @MumbaiWhId,
     @WarehouseIdsCsv = @Csv,
     @CreatedBy       = @AdminUserId;

PRINT '[L2] Done.';
GO
