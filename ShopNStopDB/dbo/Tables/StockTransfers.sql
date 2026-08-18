-- Two-step stock transfers between warehouses.
-- Status: 1=InTransit (FromWarehouse decremented), 2=Received (ToWarehouse incremented), 3=Cancelled.
CREATE TABLE [dbo].[StockTransfers]
(
    [TransferId]       INT           NOT NULL  IDENTITY(1,1),
    [VariantId]        INT           NOT NULL,
    [FromWarehouseId]  INT           NOT NULL,
    [ToWarehouseId]    INT           NOT NULL,
    [Quantity]         INT           NOT NULL,
    [Status]           TINYINT       NOT NULL  CONSTRAINT [DF_StockTransfers_Status]    DEFAULT 1,
    [Reason]           NVARCHAR(500) NULL,
    [InitiatedBy]      INT           NULL,
    [InitiatedAt]      DATETIME2(0)  NOT NULL  CONSTRAINT [DF_StockTransfers_InitiatedAt] DEFAULT GETUTCDATE(),
    [ReceivedBy]       INT           NULL,
    [ReceivedAt]       DATETIME2(0)  NULL,

    CONSTRAINT [PK_StockTransfers]                   PRIMARY KEY CLUSTERED ([TransferId] ASC),
    CONSTRAINT [CK_StockTransfers_Qty]               CHECK ([Quantity] > 0),
    CONSTRAINT [CK_StockTransfers_Status]            CHECK ([Status] IN (1,2,3)),
    CONSTRAINT [CK_StockTransfers_DifferentWarehouses] CHECK ([FromWarehouseId] <> [ToWarehouseId]),

    CONSTRAINT [FK_StockTransfers_VariantId]         FOREIGN KEY ([VariantId])       REFERENCES [dbo].[ProductVariants] ([VariantId]),
    CONSTRAINT [FK_StockTransfers_FromWarehouseId]   FOREIGN KEY ([FromWarehouseId]) REFERENCES [dbo].[Warehouses]     ([WarehouseId]),
    CONSTRAINT [FK_StockTransfers_ToWarehouseId]     FOREIGN KEY ([ToWarehouseId])   REFERENCES [dbo].[Warehouses]     ([WarehouseId]),
    CONSTRAINT [FK_StockTransfers_InitiatedBy]       FOREIGN KEY ([InitiatedBy])     REFERENCES [dbo].[Users]          ([UserId]),
    CONSTRAINT [FK_StockTransfers_ReceivedBy]        FOREIGN KEY ([ReceivedBy])      REFERENCES [dbo].[Users]          ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_StockTransfers_Status]
    ON [dbo].[StockTransfers] ([Status] ASC, [InitiatedAt] DESC);
GO
