CREATE TABLE [dbo].[PriceHistory]
(
    [HistoryId]       INT            NOT NULL  IDENTITY(1,1),
    [ProductId]       INT            NOT NULL,
    [OldMRP]          DECIMAL(18,2)  NOT NULL,
    [NewMRP]          DECIMAL(18,2)  NOT NULL,
    [OldSellingPrice] DECIMAL(18,2)  NOT NULL,
    [NewSellingPrice] DECIMAL(18,2)  NOT NULL,
    [ChangedBy]       INT            NOT NULL,
    [ChangedAt]       DATETIME2(0)   NOT NULL  CONSTRAINT [DF_PriceHistory_ChangedAt]  DEFAULT GETUTCDATE(),
    [Reason]          NVARCHAR(500)  NULL,

    CONSTRAINT [PK_PriceHistory]             PRIMARY KEY CLUSTERED ([HistoryId] ASC),

    CONSTRAINT [FK_PriceHistory_ProductId]   FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]),
    CONSTRAINT [FK_PriceHistory_ChangedBy]   FOREIGN KEY ([ChangedBy]) REFERENCES [dbo].[Users]    ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_PriceHistory_ProductId]
    ON [dbo].[PriceHistory] ([ProductId] ASC, [ChangedAt] DESC);
GO
