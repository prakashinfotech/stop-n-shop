CREATE TABLE [dbo].[SellerPerformanceScores]
(
    [PerformanceScoreId]  INT             NOT NULL  IDENTITY(1,1),
    [SellerId]            INT             NOT NULL,
    [SnapshotDate]        DATE            NOT NULL,
    [WindowDays]          INT             NOT NULL  CONSTRAINT [DF_SellerPerfScores_WindowDays] DEFAULT 30,
    [OrdersTotal]         INT             NOT NULL  CONSTRAINT [DF_SellerPerfScores_OrdersTotal]     DEFAULT 0,
    [OrdersDelivered]     INT             NOT NULL  CONSTRAINT [DF_SellerPerfScores_OrdersDelivered] DEFAULT 0,
    [OrdersCancelled]     INT             NOT NULL  CONSTRAINT [DF_SellerPerfScores_OrdersCancelled] DEFAULT 0,
    [OrdersReturned]      INT             NOT NULL  CONSTRAINT [DF_SellerPerfScores_OrdersReturned]  DEFAULT 0,
    [OnTimeDispatchPct]   DECIMAL(5,2)    NOT NULL  CONSTRAINT [DF_SellerPerfScores_OnTimeDispatch]  DEFAULT 0,
    [CancellationPct]     DECIMAL(5,2)    NOT NULL  CONSTRAINT [DF_SellerPerfScores_CancellationPct] DEFAULT 0,
    [ReturnPct]           DECIMAL(5,2)    NOT NULL  CONSTRAINT [DF_SellerPerfScores_ReturnPct]       DEFAULT 0,
    [AvgRating]           DECIMAL(3,2)    NOT NULL  CONSTRAINT [DF_SellerPerfScores_AvgRating]       DEFAULT 0,
    [CompositeScore]      DECIMAL(5,2)    NOT NULL  CONSTRAINT [DF_SellerPerfScores_Composite]       DEFAULT 0,
    [Tier]                NVARCHAR(20)    NOT NULL  CONSTRAINT [DF_SellerPerfScores_Tier]            DEFAULT N'Bronze',

    [CreatedAt]           DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerPerfScores_CreatedAt] DEFAULT GETUTCDATE(),
    [IsActive]            BIT             NOT NULL  CONSTRAINT [DF_SellerPerfScores_IsActive]  DEFAULT 1,
    [IsDeleted]           BIT             NOT NULL  CONSTRAINT [DF_SellerPerfScores_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_SellerPerformanceScores]            PRIMARY KEY CLUSTERED ([PerformanceScoreId] ASC),
    CONSTRAINT [UQ_SellerPerformanceScores_SnapDate]   UNIQUE ([SellerId], [SnapshotDate]),
    CONSTRAINT [FK_SellerPerformanceScores_SellerId]   FOREIGN KEY ([SellerId]) REFERENCES [dbo].[Sellers] ([SellerId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SellerPerformanceScores_SellerId]
    ON [dbo].[SellerPerformanceScores] ([SellerId] ASC, [SnapshotDate] DESC)
    WHERE [IsDeleted] = 0;
GO
