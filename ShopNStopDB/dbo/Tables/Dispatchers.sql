-- A Dispatcher is the person who physically moves parcels from a seller's
-- warehouse to the buyer's doorstep. One-to-one with a User (RoleId = 4).
-- Mirrors the Sellers profile pattern.
CREATE TABLE [dbo].[Dispatchers]
(
    [DispatcherId]     INT             NOT NULL  IDENTITY(1,1),
    [UserId]           INT             NOT NULL,            -- the login
    [EmployeeCode]     NVARCHAR(20)    NOT NULL,            -- e.g. DLY-001
    [VehicleNumber]    NVARCHAR(20)    NULL,                -- bike / van number plate
    [VehicleType]      NVARCHAR(20)    NULL,                -- 'bike' | 'van' | 'truck'
    [LicenseNumber]    NVARCHAR(30)    NULL,
    [BaseWarehouseId]  INT             NULL,                -- home hub; assigned warehouses in DispatcherWarehouseAssignments
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
GO

CREATE NONCLUSTERED INDEX [IX_Dispatchers_Active_Warehouse]
    ON [dbo].[Dispatchers] ([BaseWarehouseId] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
