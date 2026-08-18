-- Append-only audit log; no soft-delete, no standard audit columns.
CREATE TABLE [dbo].[AuditLogs]
(
    [AuditId]   BIGINT         NOT NULL  IDENTITY(1,1),
    [TableName] NVARCHAR(100)  NOT NULL,
    [RecordId]  INT            NOT NULL,
    [Action]    NVARCHAR(10)   NOT NULL,  -- INSERT / UPDATE / DELETE
    [OldValues] NVARCHAR(MAX)  NULL,
    [NewValues] NVARCHAR(MAX)  NULL,
    [ChangedBy] INT            NULL,
    [ChangedAt] DATETIME2(0)   NOT NULL  CONSTRAINT [DF_AuditLogs_ChangedAt]  DEFAULT GETUTCDATE(),
    [IpAddress] NVARCHAR(50)   NULL,

    CONSTRAINT [PK_AuditLogs]            PRIMARY KEY CLUSTERED ([AuditId] ASC),
    CONSTRAINT [CK_AuditLogs_Action]     CHECK ([Action] IN (N'INSERT', N'UPDATE', N'DELETE')),

    CONSTRAINT [FK_AuditLogs_ChangedBy]  FOREIGN KEY ([ChangedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_AuditLogs_TableRecordId]
    ON [dbo].[AuditLogs] ([TableName] ASC, [RecordId] ASC, [ChangedAt] DESC);
GO

CREATE NONCLUSTERED INDEX [IX_AuditLogs_ChangedAt]
    ON [dbo].[AuditLogs] ([ChangedAt] DESC);
GO
