-- Append-only ledger. Every change to Stock.OnHand or Stock.Reserved emits one row here.
-- MovementType:
--   1=Receipt (inbound), 2=Adjustment (manual correction), 3=Reserve (+Reserved),
--   4=ReleaseReservation (-Reserved), 5=Ship (-OnHand and -Reserved, commit reservation),
--   6=Return (+OnHand), 7=TransferOut (-OnHand), 8=TransferIn (+OnHand).
CREATE TABLE [dbo].[StockMovements]
(
    [MovementId]    BIGINT        NOT NULL  IDENTITY(1,1),
    [VariantId]     INT           NOT NULL,
    [WarehouseId]   INT           NOT NULL,
    [MovementType]  TINYINT       NOT NULL,
    [QuantityDelta] INT           NOT NULL,    -- Signed; +receipt, -ship, etc.
    [ReservedDelta] INT           NOT NULL  CONSTRAINT [DF_StockMovements_ReservedDelta] DEFAULT 0,
    [Reason]        NVARCHAR(500) NULL,
    [ReferenceType] NVARCHAR(50)  NULL,        -- e.g. 'Order','Reservation','Transfer','Manual'
    [ReferenceId]   BIGINT        NULL,
    [ChangedBy]     INT           NULL,
    [ChangedAt]     DATETIME2(0)  NOT NULL  CONSTRAINT [DF_StockMovements_ChangedAt] DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_StockMovements]            PRIMARY KEY CLUSTERED ([MovementId] ASC),
    CONSTRAINT [CK_StockMovements_Type]       CHECK ([MovementType] BETWEEN 1 AND 8),

    CONSTRAINT [FK_StockMovements_VariantId]   FOREIGN KEY ([VariantId])   REFERENCES [dbo].[ProductVariants] ([VariantId]),
    CONSTRAINT [FK_StockMovements_WarehouseId] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouses]     ([WarehouseId]),
    CONSTRAINT [FK_StockMovements_ChangedBy]   FOREIGN KEY ([ChangedBy])   REFERENCES [dbo].[Users]          ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_StockMovements_VariantWH_ChangedAt]
    ON [dbo].[StockMovements] ([VariantId] ASC, [WarehouseId] ASC, [ChangedAt] DESC);
GO

CREATE NONCLUSTERED INDEX [IX_StockMovements_Reference]
    ON [dbo].[StockMovements] ([ReferenceType] ASC, [ReferenceId] ASC);
GO
