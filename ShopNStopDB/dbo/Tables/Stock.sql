-- Per-(Variant,Warehouse) stock counters. Source of truth for on-hand and reserved.
-- ProductVariants.StockQuantity is kept as a denormalized cache (sum of OnHand across warehouses).
-- Concurrency: writers must take UPDLOCK,HOLDLOCK on the row before reading OnHand/Reserved.
CREATE TABLE [dbo].[Stock]
(
    [StockId]      INT          NOT NULL  IDENTITY(1,1),
    [VariantId]    INT          NOT NULL,
    [WarehouseId]  INT          NOT NULL,
    [OnHand]       INT          NOT NULL  CONSTRAINT [DF_Stock_OnHand]   DEFAULT 0,
    [Reserved]     INT          NOT NULL  CONSTRAINT [DF_Stock_Reserved] DEFAULT 0,
    [RowVersion]   ROWVERSION   NOT NULL,
    [UpdatedAt]    DATETIME2(0) NOT NULL  CONSTRAINT [DF_Stock_UpdatedAt] DEFAULT GETUTCDATE(),
    [UpdatedBy]    INT          NULL,

    CONSTRAINT [PK_Stock]                PRIMARY KEY CLUSTERED ([StockId] ASC),
    CONSTRAINT [UQ_Stock_Variant_WH]     UNIQUE ([VariantId] ASC, [WarehouseId] ASC),
    CONSTRAINT [CK_Stock_OnHand_NonNeg]  CHECK ([OnHand]   >= 0),
    CONSTRAINT [CK_Stock_Reserved_NonNeg] CHECK ([Reserved] >= 0),
    CONSTRAINT [CK_Stock_Reserved_LE_OnHand] CHECK ([Reserved] <= [OnHand]),

    CONSTRAINT [FK_Stock_VariantId]      FOREIGN KEY ([VariantId])   REFERENCES [dbo].[ProductVariants] ([VariantId]),
    CONSTRAINT [FK_Stock_WarehouseId]    FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouses]     ([WarehouseId]),
    CONSTRAINT [FK_Stock_UpdatedBy]      FOREIGN KEY ([UpdatedBy])   REFERENCES [dbo].[Users]          ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Stock_WarehouseId]
    ON [dbo].[Stock] ([WarehouseId] ASC);
GO
