-- Append-only event log; no soft-delete, no audit columns.
CREATE TABLE [dbo].[ProductViewLogs]
(
    [LogId]      BIGINT         NOT NULL  IDENTITY(1,1),
    [ProductId]  INT            NOT NULL,
    [UserId]     INT            NULL,
    [SessionId]  NVARCHAR(100)  NULL,
    [IpAddress]  NVARCHAR(50)   NULL,
    [DeviceType] NVARCHAR(50)   NULL,
    [ViewedAt]   DATETIME2(0)   NOT NULL  CONSTRAINT [DF_ProductViewLogs_ViewedAt]  DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_ProductViewLogs]             PRIMARY KEY CLUSTERED ([LogId] ASC),

    CONSTRAINT [FK_ProductViewLogs_ProductId]   FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]),
    CONSTRAINT [FK_ProductViewLogs_UserId]      FOREIGN KEY ([UserId])    REFERENCES [dbo].[Users]    ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_ProductViewLogs_ProductId]
    ON [dbo].[ProductViewLogs] ([ProductId] ASC, [ViewedAt] DESC);
GO

CREATE NONCLUSTERED INDEX [IX_ProductViewLogs_ViewedAt]
    ON [dbo].[ProductViewLogs] ([ViewedAt] DESC);
GO
