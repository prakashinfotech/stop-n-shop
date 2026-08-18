CREATE TABLE [dbo].[SellerAnalyticsDaily]
(
    [AnalyticsId]         INT            NOT NULL  IDENTITY(1,1),
    [SellerId]            INT            NOT NULL,
    [AnalyticsDate]       DATE           NOT NULL,
    [TotalOrders]         INT            NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_TotalOrders]         DEFAULT 0,
    [TotalRevenue]        DECIMAL(18,2)  NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_TotalRevenue]        DEFAULT 0,
    [TotalCommission]     DECIMAL(18,2)  NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_TotalCommission]     DEFAULT 0,
    [TotalEarnings]       DECIMAL(18,2)  NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_TotalEarnings]       DEFAULT 0,
    [TotalProductViews]   INT            NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_TotalProductViews]   DEFAULT 0,
    [TotalUniqueVisitors] INT            NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_TotalUniqueVisitors] DEFAULT 0,

    [CreatedAt]           DATETIME2(0)   NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_CreatedAt]           DEFAULT GETUTCDATE(),
    [UpdatedAt]           DATETIME2(0)   NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_UpdatedAt]           DEFAULT GETUTCDATE(),
    [CreatedBy]           INT            NULL,
    [UpdatedBy]           INT            NULL,
    [IsActive]            BIT            NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_IsActive]            DEFAULT 1,
    [IsDeleted]           BIT            NOT NULL  CONSTRAINT [DF_SellerAnalyticsDaily_IsDeleted]           DEFAULT 0,

    CONSTRAINT [PK_SellerAnalyticsDaily]             PRIMARY KEY CLUSTERED ([AnalyticsId] ASC),
    CONSTRAINT [UQ_SellerAnalyticsDaily_SellerDate]  UNIQUE ([SellerId], [AnalyticsDate]),

    CONSTRAINT [FK_SellerAnalyticsDaily_SellerId]    FOREIGN KEY ([SellerId])  REFERENCES [dbo].[Sellers] ([SellerId]),
    CONSTRAINT [FK_SellerAnalyticsDaily_CreatedBy]   FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_SellerAnalyticsDaily_UpdatedBy]   FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]   ([UserId])
);
GO
