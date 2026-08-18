CREATE TABLE [dbo].[Orders]
(
    [OrderId]                  INT             NOT NULL  IDENTITY(1,1),
    [UserId]                   INT             NOT NULL,
    [OrderNumber]              NVARCHAR(50)    NOT NULL,
    [OrderStatus]              TINYINT         NOT NULL  CONSTRAINT [DF_Orders_OrderStatus]     DEFAULT 1,  -- 1=Pending,2=Confirmed,3=Processing,4=Shipped,5=Delivered,6=Cancelled,7=Returned
    [SubTotal]                 DECIMAL(18,2)   NOT NULL,
    [DiscountAmount]           DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_Orders_DiscountAmount]   DEFAULT 0,
    [CouponId]                 INT             NULL,
    [CouponDiscount]           DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_Orders_CouponDiscount]   DEFAULT 0,
    [TaxAmount]                DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_Orders_TaxAmount]        DEFAULT 0,
    [ShippingCharge]           DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_Orders_ShippingCharge]   DEFAULT 0,
    [TotalAmount]              DECIMAL(18,2)   NOT NULL,
    [ShippingAddressId]        INT             NOT NULL,
    [PaymentMode]              TINYINT         NOT NULL,  -- 1=COD, 2=Online, 3=Wallet
    [PaymentStatus]            TINYINT         NOT NULL  CONSTRAINT [DF_Orders_PaymentStatus]    DEFAULT 1,  -- 1=Pending,2=Paid,3=Failed,4=Refunded
    [PaymentGatewayRef]        NVARCHAR(200)   NULL,
    [PaymentGatewayResponse]   NVARCHAR(MAX)   NULL,
    [ExpectedDeliveryDate]     DATE            NULL,
    [DeliveredAt]              DATETIME2(0)    NULL,
    [CancelledAt]              DATETIME2(0)    NULL,
    [CancellationReason]       NVARCHAR(500)   NULL,
    [EmailSentAt]              DATETIME2(0)    NULL,
    [SmsSentAt]                DATETIME2(0)    NULL,

    [CreatedAt]                DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Orders_CreatedAt]        DEFAULT GETUTCDATE(),
    [UpdatedAt]                DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Orders_UpdatedAt]        DEFAULT GETUTCDATE(),
    [CreatedBy]                INT             NULL,
    [UpdatedBy]                INT             NULL,
    [IsActive]                 BIT             NOT NULL  CONSTRAINT [DF_Orders_IsActive]         DEFAULT 1,
    [IsDeleted]                BIT             NOT NULL  CONSTRAINT [DF_Orders_IsDeleted]        DEFAULT 0,

    CONSTRAINT [PK_Orders]                     PRIMARY KEY CLUSTERED ([OrderId] ASC),
    CONSTRAINT [UQ_Orders_OrderNumber]         UNIQUE ([OrderNumber]),
    CONSTRAINT [CK_Orders_OrderStatus]         CHECK ([OrderStatus]  IN (1, 2, 3, 4, 5, 6, 7)),
    CONSTRAINT [CK_Orders_PaymentMode]         CHECK ([PaymentMode]  IN (1, 2, 3)),
    CONSTRAINT [CK_Orders_PaymentStatus]       CHECK ([PaymentStatus] IN (1, 2, 3, 4)),

    CONSTRAINT [FK_Orders_UserId]              FOREIGN KEY ([UserId])            REFERENCES [dbo].[Users]         ([UserId]),
    CONSTRAINT [FK_Orders_CouponId]            FOREIGN KEY ([CouponId])          REFERENCES [dbo].[Coupons]       ([CouponId]),
    CONSTRAINT [FK_Orders_ShippingAddressId]   FOREIGN KEY ([ShippingAddressId]) REFERENCES [dbo].[UserAddresses] ([AddressId]),
    CONSTRAINT [FK_Orders_CreatedBy]           FOREIGN KEY ([CreatedBy])         REFERENCES [dbo].[Users]         ([UserId]),
    CONSTRAINT [FK_Orders_UpdatedBy]           FOREIGN KEY ([UpdatedBy])         REFERENCES [dbo].[Users]         ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Orders_UserId]
    ON [dbo].[Orders] ([UserId] ASC, [OrderStatus] ASC, [CreatedAt] DESC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_Orders_OrderStatus]
    ON [dbo].[Orders] ([OrderStatus] ASC, [CreatedAt] DESC)
    WHERE [IsDeleted] = 0;
GO
