-- Soft holds on stock for in-flight checkouts. ExpiresAt drives the reservation TTL.
-- Status: 1=Active, 2=Committed (became order), 3=Released, 4=Expired.
CREATE TABLE [dbo].[StockReservations]
(
    [ReservationId] BIGINT       NOT NULL  IDENTITY(1,1),
    [VariantId]     INT          NOT NULL,
    [WarehouseId]   INT          NOT NULL,
    [UserId]        INT          NULL,           -- Buyer holding the cart, NULL for system holds
    [CartLineId]    INT          NULL,           -- Optional pointer to Cart row
    [Quantity]      INT          NOT NULL,
    [Status]        TINYINT      NOT NULL  CONSTRAINT [DF_StockReservations_Status]    DEFAULT 1,
    [ExpiresAt]     DATETIME2(0) NOT NULL,
    [CreatedAt]     DATETIME2(0) NOT NULL  CONSTRAINT [DF_StockReservations_CreatedAt] DEFAULT GETUTCDATE(),
    [ReleasedAt]    DATETIME2(0) NULL,
    [OrderId]       INT          NULL,           -- Set when Status moves to Committed

    CONSTRAINT [PK_StockReservations]      PRIMARY KEY CLUSTERED ([ReservationId] ASC),
    CONSTRAINT [CK_StockReservations_Qty]    CHECK ([Quantity] > 0),
    CONSTRAINT [CK_StockReservations_Status] CHECK ([Status] IN (1,2,3,4)),

    CONSTRAINT [FK_StockReservations_VariantId]   FOREIGN KEY ([VariantId])   REFERENCES [dbo].[ProductVariants] ([VariantId]),
    CONSTRAINT [FK_StockReservations_WarehouseId] FOREIGN KEY ([WarehouseId]) REFERENCES [dbo].[Warehouses]     ([WarehouseId]),
    CONSTRAINT [FK_StockReservations_UserId]      FOREIGN KEY ([UserId])      REFERENCES [dbo].[Users]          ([UserId]),
    CONSTRAINT [FK_StockReservations_OrderId]     FOREIGN KEY ([OrderId])     REFERENCES [dbo].[Orders]         ([OrderId])
);
GO

CREATE NONCLUSTERED INDEX [IX_StockReservations_Active_Expiry]
    ON [dbo].[StockReservations] ([Status] ASC, [ExpiresAt] ASC)
    INCLUDE ([VariantId], [WarehouseId], [Quantity])
    WHERE [Status] = 1;
GO

CREATE NONCLUSTERED INDEX [IX_StockReservations_VariantWH]
    ON [dbo].[StockReservations] ([VariantId] ASC, [WarehouseId] ASC, [Status] ASC);
GO
