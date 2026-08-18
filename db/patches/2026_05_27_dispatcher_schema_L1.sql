/*
 * 2026-05-27 — Dispatcher workstream L1 (schema only)
 *
 * Establishes the data model for the dispatcher / warehouse-to-doorstep
 * logistics flow. Pure schema + role seed — no SPs, no controllers, no UI.
 * Those come in L2 onwards.
 *
 * Adds:
 *   • Role 4 = Dispatcher
 *   • Dispatchers + DispatcherWarehouseAssignments
 *   • DeliveryAssignments + DeliveryAttempts
 *   • DispatcherLocationPings + DispatcherCurrentPositions (for L6 live tracking)
 *   • Extends CK_OrderItems_OrderStatus to allow status codes 10/11/12
 *
 * Idempotent: every CREATE is guarded by IF NOT EXISTS; the role MERGE
 * matches on RoleId; the CHECK constraint update is DROP + ADD.
 *
 * Apply:
 *   docker cp db/patches/2026_05_27_dispatcher_schema_L1.sql stopnshop-db:/tmp/l1.sql
 *   docker exec -i stopnshop-db /opt/mssql-tools18/bin/sqlcmd \
 *     -S localhost -U sa -P "$SA_PASSWORD" -C -d ShopNShop_db -b -I -i /tmp/l1.sql
 */

SET NOCOUNT ON;

------------------------------------------------------------------------------
-- 1. Role 4 = Dispatcher
------------------------------------------------------------------------------
PRINT '[L1] Ensuring Role 4 (Dispatcher)...';
MERGE [dbo].[Roles] AS tgt
USING (VALUES (4, N'Dispatcher')) AS src ([RoleId], [RoleName])
ON tgt.[RoleId] = src.[RoleId]
WHEN MATCHED AND tgt.[RoleName] <> src.[RoleName] THEN UPDATE SET tgt.[RoleName] = src.[RoleName]
WHEN NOT MATCHED THEN INSERT ([RoleId], [RoleName]) VALUES (src.[RoleId], src.[RoleName]);

------------------------------------------------------------------------------
-- 2. Dispatchers
------------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[Dispatchers]', N'U') IS NULL
BEGIN
    PRINT '[L1] Creating Dispatchers table...';
    CREATE TABLE [dbo].[Dispatchers]
    (
        [DispatcherId]     INT             NOT NULL  IDENTITY(1,1),
        [UserId]           INT             NOT NULL,
        [EmployeeCode]     NVARCHAR(20)    NOT NULL,
        [VehicleNumber]    NVARCHAR(20)    NULL,
        [VehicleType]      NVARCHAR(20)    NULL,
        [LicenseNumber]    NVARCHAR(30)    NULL,
        [BaseWarehouseId]  INT             NULL,
        [JoinedAt]         DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Dispatchers_JoinedAt] DEFAULT GETUTCDATE(),
        [CreatedAt]        DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Dispatchers_CreatedAt] DEFAULT GETUTCDATE(),
        [UpdatedAt]        DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Dispatchers_UpdatedAt] DEFAULT GETUTCDATE(),
        [CreatedBy]        INT             NULL,
        [UpdatedBy]        INT             NULL,
        [IsActive]         BIT             NOT NULL  CONSTRAINT [DF_Dispatchers_IsActive]  DEFAULT 1,
        [IsDeleted]        BIT             NOT NULL  CONSTRAINT [DF_Dispatchers_IsDeleted] DEFAULT 0,

        CONSTRAINT [PK_Dispatchers]                  PRIMARY KEY CLUSTERED ([DispatcherId] ASC),
        CONSTRAINT [UQ_Dispatchers_EmployeeCode]     UNIQUE ([EmployeeCode]),
        CONSTRAINT [UQ_Dispatchers_UserId]           UNIQUE ([UserId]),
        CONSTRAINT [FK_Dispatchers_UserId]           FOREIGN KEY ([UserId])          REFERENCES [dbo].[Users]      ([UserId]),
        CONSTRAINT [FK_Dispatchers_BaseWarehouseId]  FOREIGN KEY ([BaseWarehouseId]) REFERENCES [dbo].[Warehouses] ([WarehouseId]),
        CONSTRAINT [FK_Dispatchers_CreatedBy]        FOREIGN KEY ([CreatedBy])       REFERENCES [dbo].[Users]      ([UserId]),
        CONSTRAINT [FK_Dispatchers_UpdatedBy]        FOREIGN KEY ([UpdatedBy])       REFERENCES [dbo].[Users]      ([UserId])
    );

    CREATE NONCLUSTERED INDEX [IX_Dispatchers_Active_Warehouse]
        ON [dbo].[Dispatchers] ([BaseWarehouseId] ASC)
        WHERE [IsDeleted] = 0 AND [IsActive] = 1;
END
ELSE
    PRINT '[L1] Dispatchers already exists — skipping.';
GO

------------------------------------------------------------------------------
-- 3. DispatcherWarehouseAssignments
------------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[DispatcherWarehouseAssignments]', N'U') IS NULL
BEGIN
    PRINT '[L1] Creating DispatcherWarehouseAssignments...';
    CREATE TABLE [dbo].[DispatcherWarehouseAssignments]
    (
        [DispatcherId]  INT             NOT NULL,
        [WarehouseId]   INT             NOT NULL,
        [AssignedAt]    DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DWA_AssignedAt] DEFAULT GETUTCDATE(),
        [AssignedBy]    INT             NULL,

        CONSTRAINT [PK_DispatcherWarehouseAssignments]   PRIMARY KEY CLUSTERED ([DispatcherId] ASC, [WarehouseId] ASC),
        CONSTRAINT [FK_DWA_DispatcherId]                 FOREIGN KEY ([DispatcherId]) REFERENCES [dbo].[Dispatchers] ([DispatcherId]),
        CONSTRAINT [FK_DWA_WarehouseId]                  FOREIGN KEY ([WarehouseId])  REFERENCES [dbo].[Warehouses]  ([WarehouseId]),
        CONSTRAINT [FK_DWA_AssignedBy]                   FOREIGN KEY ([AssignedBy])   REFERENCES [dbo].[Users]       ([UserId])
    );

    CREATE NONCLUSTERED INDEX [IX_DWA_Warehouse]
        ON [dbo].[DispatcherWarehouseAssignments] ([WarehouseId] ASC, [DispatcherId] ASC);
END
ELSE
    PRINT '[L1] DispatcherWarehouseAssignments already exists — skipping.';
GO

------------------------------------------------------------------------------
-- 4. DeliveryAssignments
------------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[DeliveryAssignments]', N'U') IS NULL
BEGIN
    PRINT '[L1] Creating DeliveryAssignments...';
    CREATE TABLE [dbo].[DeliveryAssignments]
    (
        [AssignmentId]      INT             NOT NULL  IDENTITY(1,1),
        [OrderItemId]       INT             NOT NULL,
        [DispatcherId]      INT             NOT NULL,
        [WarehouseId]       INT             NOT NULL,
        [Status]            TINYINT         NOT NULL  CONSTRAINT [DF_DA_Status] DEFAULT 10,
        [AssignedAt]        DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DA_AssignedAt] DEFAULT GETUTCDATE(),
        [PickedUpAt]        DATETIME2(0)    NULL,
        [OutForDeliveryAt]  DATETIME2(0)    NULL,
        [DeliveredAt]       DATETIME2(0)    NULL,
        [DeliveryOtp]       NVARCHAR(6)     NULL,
        [DeliveryOtpSentAt] DATETIME2(0)    NULL,
        [DeliveryProofUrl]  NVARCHAR(500)   NULL,
        [DeliveryGpsLat]    DECIMAL(9,6)    NULL,
        [DeliveryGpsLng]    DECIMAL(9,6)    NULL,
        [CodAmount]         DECIMAL(18,2)   NULL,
        [CodCollected]      DECIMAL(18,2)   NULL,
        [CodSettledAt]      DATETIME2(0)    NULL,
        [FailureReason]     NVARCHAR(500)   NULL,
        [AttemptNumber]     TINYINT         NOT NULL  CONSTRAINT [DF_DA_AttemptNumber] DEFAULT 1,
        [CreatedAt]         DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DA_CreatedAt] DEFAULT GETUTCDATE(),
        [UpdatedAt]         DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DA_UpdatedAt] DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_DeliveryAssignments]   PRIMARY KEY CLUSTERED ([AssignmentId] ASC),
        CONSTRAINT [CK_DA_Status]             CHECK ([Status] IN (10, 4, 9, 5, 11, 12)),
        CONSTRAINT [FK_DA_OrderItemId]        FOREIGN KEY ([OrderItemId])  REFERENCES [dbo].[OrderItems]  ([OrderItemId]),
        CONSTRAINT [FK_DA_DispatcherId]       FOREIGN KEY ([DispatcherId]) REFERENCES [dbo].[Dispatchers] ([DispatcherId]),
        CONSTRAINT [FK_DA_WarehouseId]        FOREIGN KEY ([WarehouseId])  REFERENCES [dbo].[Warehouses]  ([WarehouseId])
    );

    CREATE NONCLUSTERED INDEX [IX_DA_Dispatcher_Active]
        ON [dbo].[DeliveryAssignments] ([DispatcherId] ASC, [Status] ASC, [AssignedAt] DESC)
        INCLUDE ([OrderItemId], [WarehouseId]);

    CREATE NONCLUSTERED INDEX [IX_DA_OrderItem]
        ON [dbo].[DeliveryAssignments] ([OrderItemId] ASC, [AssignedAt] DESC);
END
ELSE
    PRINT '[L1] DeliveryAssignments already exists — skipping.';
GO

------------------------------------------------------------------------------
-- 5. DeliveryAttempts
------------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[DeliveryAttempts]', N'U') IS NULL
BEGIN
    PRINT '[L1] Creating DeliveryAttempts...';
    CREATE TABLE [dbo].[DeliveryAttempts]
    (
        [AttemptId]              INT             NOT NULL  IDENTITY(1,1),
        [AssignmentId]           INT             NOT NULL,
        [AttemptNumber]          TINYINT         NOT NULL,
        [AttemptedAt]            DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DAtt_AttemptedAt] DEFAULT GETUTCDATE(),
        [Outcome]                NVARCHAR(30)    NOT NULL,
        [Notes]                  NVARCHAR(500)   NULL,
        [GpsLat]                 DECIMAL(9,6)    NULL,
        [GpsLng]                 DECIMAL(9,6)    NULL,
        [NextAttemptScheduledAt] DATETIME2(0)    NULL,

        CONSTRAINT [PK_DeliveryAttempts]   PRIMARY KEY CLUSTERED ([AttemptId] ASC),
        CONSTRAINT [CK_DAtt_Outcome]       CHECK ([Outcome] IN
            (N'DELIVERED', N'NOT_HOME', N'WRONG_ADDR', N'REFUSED', N'OTP_FAIL', N'OTHER')),
        CONSTRAINT [FK_DAtt_AssignmentId]  FOREIGN KEY ([AssignmentId])
            REFERENCES [dbo].[DeliveryAssignments] ([AssignmentId])
    );

    CREATE NONCLUSTERED INDEX [IX_DAtt_AssignmentId]
        ON [dbo].[DeliveryAttempts] ([AssignmentId] ASC, [AttemptNumber] ASC);
END
ELSE
    PRINT '[L1] DeliveryAttempts already exists — skipping.';
GO

------------------------------------------------------------------------------
-- 6. DispatcherLocationPings (live-tracking time-series)
------------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[DispatcherLocationPings]', N'U') IS NULL
BEGIN
    PRINT '[L1] Creating DispatcherLocationPings...';
    CREATE TABLE [dbo].[DispatcherLocationPings]
    (
        [PingId]         BIGINT          NOT NULL  IDENTITY(1,1),
        [AssignmentId]   INT             NOT NULL,
        [DispatcherId]   INT             NOT NULL,
        [Lat]            DECIMAL(9,6)    NOT NULL,
        [Lng]            DECIMAL(9,6)    NOT NULL,
        [Heading]        DECIMAL(5,2)    NULL,
        [SpeedKmh]       DECIMAL(5,2)    NULL,
        [Accuracy]       DECIMAL(7,2)    NULL,
        [BatteryPct]     TINYINT         NULL,
        [CapturedAt]     DATETIME2(0)    NOT NULL,
        [ReceivedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DLP_ReceivedAt] DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_DispatcherLocationPings]   PRIMARY KEY CLUSTERED ([PingId] ASC),
        CONSTRAINT [FK_DLP_AssignmentId]          FOREIGN KEY ([AssignmentId]) REFERENCES [dbo].[DeliveryAssignments] ([AssignmentId]),
        CONSTRAINT [FK_DLP_DispatcherId]          FOREIGN KEY ([DispatcherId]) REFERENCES [dbo].[Dispatchers]         ([DispatcherId])
    );

    CREATE NONCLUSTERED INDEX [IX_DLP_Assignment_Captured]
        ON [dbo].[DispatcherLocationPings] ([AssignmentId] ASC, [CapturedAt] DESC);

    CREATE NONCLUSTERED INDEX [IX_DLP_ReceivedAt]
        ON [dbo].[DispatcherLocationPings] ([ReceivedAt] ASC);
END
ELSE
    PRINT '[L1] DispatcherLocationPings already exists — skipping.';
GO

------------------------------------------------------------------------------
-- 7. DispatcherCurrentPositions (materialised latest position per assignment)
------------------------------------------------------------------------------
IF OBJECT_ID(N'[dbo].[DispatcherCurrentPositions]', N'U') IS NULL
BEGIN
    PRINT '[L1] Creating DispatcherCurrentPositions...';
    CREATE TABLE [dbo].[DispatcherCurrentPositions]
    (
        [AssignmentId]  INT             NOT NULL,
        [Lat]           DECIMAL(9,6)    NOT NULL,
        [Lng]           DECIMAL(9,6)    NOT NULL,
        [Heading]       DECIMAL(5,2)    NULL,
        [SpeedKmh]      DECIMAL(5,2)    NULL,
        [EtaMinutes]    INT             NULL,
        [UpdatedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DCP_UpdatedAt] DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_DispatcherCurrentPositions]   PRIMARY KEY CLUSTERED ([AssignmentId] ASC),
        CONSTRAINT [FK_DCP_AssignmentId]             FOREIGN KEY ([AssignmentId]) REFERENCES [dbo].[DeliveryAssignments] ([AssignmentId])
    );
END
ELSE
    PRINT '[L1] DispatcherCurrentPositions already exists — skipping.';
GO

------------------------------------------------------------------------------
-- 8. Extend OrderItems CHECK constraint to allow new dispatcher statuses
------------------------------------------------------------------------------
PRINT '[L1] Updating CK_OrderItems_OrderStatus to allow 10/11/12...';
IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_OrderItems_OrderStatus'
      AND parent_object_id = OBJECT_ID('dbo.OrderItems')
)
    ALTER TABLE [dbo].[OrderItems] DROP CONSTRAINT [CK_OrderItems_OrderStatus];

ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [CK_OrderItems_OrderStatus]
    CHECK ([OrderStatus] IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12));
GO

PRINT '[L1] Done.';
GO
