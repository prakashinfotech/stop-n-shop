-- Append-only timeline of order status transitions. Drives the buyer's
-- order-detail tracking strip and any downstream notifications dashboard.
--
-- One row is written per (OrderId, Status) transition. Status is stored
-- as the UI-facing UPPERCASE string label (PLACED / CONFIRMED / PACKED /
-- DISPATCHED / OUT_FOR_DELIVERY / DELIVERED / CANCELLED / REJECTED /
-- RETURNED) so the API can pass it through to the buyer untouched.
--
-- OrderItemId is nullable — entries written at the order-header level
-- (PLACED, CANCELLED) leave it NULL; entries triggered by a specific
-- line (CONFIRMED, REJECTED, the per-line fulfilment stages) record
-- the item that caused the transition.
CREATE TABLE [dbo].[OrderTrackings]
(
    [TrackingId]   INT             NOT NULL  IDENTITY(1,1),
    [OrderId]      INT             NOT NULL,
    [OrderItemId]  INT             NULL,
    [Status]       NVARCHAR(40)    NOT NULL,
    [Note]         NVARCHAR(500)   NULL,
    [ChangedAt]    DATETIME2(0)    NOT NULL  CONSTRAINT [DF_OrderTrackings_ChangedAt] DEFAULT GETUTCDATE(),
    [ChangedBy]    INT             NULL,

    CONSTRAINT [PK_OrderTrackings]              PRIMARY KEY CLUSTERED ([TrackingId] ASC),
    CONSTRAINT [FK_OrderTrackings_OrderId]      FOREIGN KEY ([OrderId])     REFERENCES [dbo].[Orders]     ([OrderId]),
    CONSTRAINT [FK_OrderTrackings_OrderItemId]  FOREIGN KEY ([OrderItemId]) REFERENCES [dbo].[OrderItems] ([OrderItemId]),
    CONSTRAINT [FK_OrderTrackings_ChangedBy]    FOREIGN KEY ([ChangedBy])   REFERENCES [dbo].[Users]      ([UserId])
);
GO

-- The buyer-detail query reads tracking-for-order ordered by ChangedAt; this
-- index makes that a seek + range scan instead of a clustered-index scan.
CREATE NONCLUSTERED INDEX [IX_OrderTrackings_Order_Changed]
    ON [dbo].[OrderTrackings] ([OrderId] ASC, [ChangedAt] ASC);
GO
