CREATE TABLE [dbo].[OrderItems]
(
    [OrderItemId]          INT             NOT NULL  IDENTITY(1,1),
    [OrderId]              INT             NOT NULL,
    [ProductId]            INT             NOT NULL,
    [VariantId]            INT             NOT NULL,
    [SellerId]             INT             NOT NULL,
    [BrandId]              INT             NOT NULL,
    [ProductName]          NVARCHAR(300)   NOT NULL,
    [VariantSnapshot]      NVARCHAR(300)   NULL,
    [Quantity]             INT             NOT NULL,
    [UnitPrice]            DECIMAL(18,2)   NOT NULL,
    [DiscountAmount]       DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_OrderItems_DiscountAmount]        DEFAULT 0,
    [TaxAmount]            DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_OrderItems_TaxAmount]             DEFAULT 0,
    [TotalPrice]           DECIMAL(18,2)   NOT NULL,
    [SellerCommissionRate] DECIMAL(5,2)    NULL,
    [CommissionAmount]     DECIMAL(18,2)   NULL,
    [SellerEarning]        DECIMAL(18,2)   NULL,
    [IsReturned]           BIT             NOT NULL  CONSTRAINT [DF_OrderItems_IsReturned]            DEFAULT 0,
    [ReturnReason]         NVARCHAR(500)   NULL,

    -- Per-line fulfilment status. Set initially by the seller (1→2→3) then
    -- progressed by the dispatcher (3→10→4→9→5) once the parcel hands off.
    --   1=Placed (default), 2=Confirmed, 3=Packed,
    --   10=PickedUp (dispatcher claimed at warehouse),
    --   4=Dispatched (in transit hub-to-hub),
    --   9=OutForDelivery (with last-mile dispatcher),
    --   5=Delivered, 6=Cancelled, 7=Returned, 8=Rejected,
    --   11=DeliveryFailed (attempt failed, retry queued),
    --   12=ReturnToOrigin (max retries, going back to seller).
    -- Codes 9–12 sit out of numerical order — by design, to avoid renumbering
    -- existing rows when the flow expanded.
    [OrderStatus]          TINYINT         NOT NULL  CONSTRAINT [DF_OrderItems_OrderStatus]           DEFAULT 1,
    [ConfirmedAt]          DATETIME2(0)    NULL,
    [RejectedAt]           DATETIME2(0)    NULL,
    [RejectedBySellerId]   INT             NULL,
    [RejectionReason]      NVARCHAR(500)   NULL,

    [CreatedAt]            DATETIME2(0)    NOT NULL  CONSTRAINT [DF_OrderItems_CreatedAt]             DEFAULT GETUTCDATE(),
    [UpdatedAt]            DATETIME2(0)    NOT NULL  CONSTRAINT [DF_OrderItems_UpdatedAt]             DEFAULT GETUTCDATE(),
    [CreatedBy]            INT             NULL,
    [UpdatedBy]            INT             NULL,
    [IsActive]             BIT             NOT NULL  CONSTRAINT [DF_OrderItems_IsActive]              DEFAULT 1,
    [IsDeleted]            BIT             NOT NULL  CONSTRAINT [DF_OrderItems_IsDeleted]             DEFAULT 0,

    CONSTRAINT [PK_OrderItems]               PRIMARY KEY CLUSTERED ([OrderItemId] ASC),
    CONSTRAINT [CK_OrderItems_OrderStatus]   CHECK ([OrderStatus] IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)),

    CONSTRAINT [FK_OrderItems_OrderId]       FOREIGN KEY ([OrderId])   REFERENCES [dbo].[Orders]         ([OrderId]),
    CONSTRAINT [FK_OrderItems_ProductId]     FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products]        ([ProductId]),
    CONSTRAINT [FK_OrderItems_VariantId]     FOREIGN KEY ([VariantId]) REFERENCES [dbo].[ProductVariants] ([VariantId]),
    CONSTRAINT [FK_OrderItems_SellerId]      FOREIGN KEY ([SellerId])  REFERENCES [dbo].[Sellers]         ([SellerId]),
    CONSTRAINT [FK_OrderItems_BrandId]           FOREIGN KEY ([BrandId])            REFERENCES [dbo].[Brands]  ([BrandId]),
    CONSTRAINT [FK_OrderItems_RejectedBySeller]  FOREIGN KEY ([RejectedBySellerId]) REFERENCES [dbo].[Sellers] ([SellerId]),
    CONSTRAINT [FK_OrderItems_CreatedBy]     FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]           ([UserId]),
    CONSTRAINT [FK_OrderItems_UpdatedBy]     FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]           ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_OrderItems_OrderId]
    ON [dbo].[OrderItems] ([OrderId] ASC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_OrderItems_SellerId]
    ON [dbo].[OrderItems] ([SellerId] ASC, [CreatedAt] DESC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_OrderItems_SellerQueue]
    ON [dbo].[OrderItems] ([SellerId] ASC, [OrderStatus] ASC, [CreatedAt] DESC)
    WHERE [IsDeleted] = 0;
GO
