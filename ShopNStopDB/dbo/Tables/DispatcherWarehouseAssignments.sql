-- m:n bridge — a dispatcher can serve multiple warehouses, a warehouse can be
-- served by multiple dispatchers. Drives the pickup-queue filter ("show me
-- Packed orders at warehouses I'm assigned to").
CREATE TABLE [dbo].[DispatcherWarehouseAssignments]
(
    [DispatcherId]  INT             NOT NULL,
    [WarehouseId]   INT             NOT NULL,
    [AssignedAt]    DATETIME2(0)    NOT NULL  CONSTRAINT [DF_DWA_AssignedAt] DEFAULT GETUTCDATE(),
    [AssignedBy]    INT             NULL,                  -- admin who assigned

    CONSTRAINT [PK_DispatcherWarehouseAssignments]   PRIMARY KEY CLUSTERED ([DispatcherId] ASC, [WarehouseId] ASC),
    CONSTRAINT [FK_DWA_DispatcherId]                 FOREIGN KEY ([DispatcherId]) REFERENCES [dbo].[Dispatchers] ([DispatcherId]),
    CONSTRAINT [FK_DWA_WarehouseId]                  FOREIGN KEY ([WarehouseId])  REFERENCES [dbo].[Warehouses]  ([WarehouseId]),
    CONSTRAINT [FK_DWA_AssignedBy]                   FOREIGN KEY ([AssignedBy])   REFERENCES [dbo].[Users]       ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_DWA_Warehouse]
    ON [dbo].[DispatcherWarehouseAssignments] ([WarehouseId] ASC, [DispatcherId] ASC);
GO
