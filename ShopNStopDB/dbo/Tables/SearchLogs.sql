-- Append-only event log; no soft-delete, no audit columns.
CREATE TABLE [dbo].[SearchLogs]
(
    [SearchId]         BIGINT         NOT NULL  IDENTITY(1,1),
    [UserId]           INT            NULL,
    [SearchTerm]       NVARCHAR(500)  NOT NULL,
    [ResultCount]      INT            NOT NULL  CONSTRAINT [DF_SearchLogs_ResultCount]  DEFAULT 0,
    [ClickedProductId] INT            NULL,
    [SearchedAt]       DATETIME2(0)   NOT NULL  CONSTRAINT [DF_SearchLogs_SearchedAt]   DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_SearchLogs]                    PRIMARY KEY CLUSTERED ([SearchId] ASC),

    CONSTRAINT [FK_SearchLogs_UserId]             FOREIGN KEY ([UserId])           REFERENCES [dbo].[Users]    ([UserId]),
    CONSTRAINT [FK_SearchLogs_ClickedProductId]   FOREIGN KEY ([ClickedProductId]) REFERENCES [dbo].[Products] ([ProductId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SearchLogs_SearchedAt]
    ON [dbo].[SearchLogs] ([SearchedAt] DESC);
GO

CREATE NONCLUSTERED INDEX [IX_SearchLogs_SearchTerm]
    ON [dbo].[SearchLogs] ([SearchTerm] ASC);
GO
