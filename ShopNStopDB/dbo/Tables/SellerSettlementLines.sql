CREATE TABLE [dbo].[SellerSettlementLines]
(
    [SettlementLineId]   INT             NOT NULL  IDENTITY(1,1),
    [SettlementId]       INT             NOT NULL,
    [OrderItemId]        INT             NOT NULL,
    [OrderId]            INT             NOT NULL,
    [GrossAmount]        DECIMAL(18,2)   NOT NULL,
    [CommissionAmount]   DECIMAL(18,2)   NOT NULL,
    [TdsAmount]          DECIMAL(18,2)   NOT NULL,
    [PenaltyAmount]      DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_SellerSettlementLines_Penalty] DEFAULT 0,
    [NetAmount]          DECIMAL(18,2)   NOT NULL,

    [CreatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerSettlementLines_CreatedAt] DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_SellerSettlementLines]               PRIMARY KEY CLUSTERED ([SettlementLineId] ASC),
    CONSTRAINT [UQ_SellerSettlementLines_OrderItem]     UNIQUE ([OrderItemId]),
    CONSTRAINT [FK_SellerSettlementLines_Settlement]    FOREIGN KEY ([SettlementId]) REFERENCES [dbo].[SellerSettlements] ([SettlementId]),
    CONSTRAINT [FK_SellerSettlementLines_OrderItem]     FOREIGN KEY ([OrderItemId])  REFERENCES [dbo].[OrderItems]        ([OrderItemId]),
    CONSTRAINT [FK_SellerSettlementLines_Order]         FOREIGN KEY ([OrderId])      REFERENCES [dbo].[Orders]            ([OrderId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SellerSettlementLines_SettlementId]
    ON [dbo].[SellerSettlementLines] ([SettlementId] ASC);
GO
