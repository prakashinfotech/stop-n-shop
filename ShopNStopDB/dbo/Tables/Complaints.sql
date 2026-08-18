CREATE TABLE [dbo].[Complaints]
(
    [ComplaintId]   INT             NOT NULL  IDENTITY(1,1),
    [UserId]        INT             NOT NULL,
    [OrderId]       INT             NULL,         -- optional context
    [Category]      NVARCHAR(50)    NOT NULL,     -- 'delivery' | 'product' | 'payment' | 'account' | 'other'
    [Subject]       NVARCHAR(300)   NOT NULL,
    [Body]          NVARCHAR(MAX)   NOT NULL,
    [Status]        TINYINT         NOT NULL  CONSTRAINT [DF_Complaints_Status] DEFAULT 1,
        -- 1 = Open, 2 = InProgress, 3 = Resolved, 4 = Closed
    [AdminNote]     NVARCHAR(MAX)   NULL,
    [Source]        NVARCHAR(20)    NOT NULL  CONSTRAINT [DF_Complaints_Source] DEFAULT N'aria',
        -- 'aria' | 'web' | 'support' — future-proof for the dedicated tech-support surface

    [CreatedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Complaints_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Complaints_UpdatedAt] DEFAULT GETUTCDATE(),
    [UpdatedBy]     INT             NULL,
    [IsDeleted]     BIT             NOT NULL  CONSTRAINT [DF_Complaints_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_Complaints]            PRIMARY KEY CLUSTERED ([ComplaintId] ASC),
    CONSTRAINT [CK_Complaints_Status]     CHECK ([Status]   IN (1, 2, 3, 4)),
    CONSTRAINT [CK_Complaints_Category]   CHECK ([Category] IN (N'delivery', N'product', N'payment', N'account', N'other')),

    CONSTRAINT [FK_Complaints_UserId]     FOREIGN KEY ([UserId])    REFERENCES [dbo].[Users]  ([UserId]),
    CONSTRAINT [FK_Complaints_OrderId]    FOREIGN KEY ([OrderId])   REFERENCES [dbo].[Orders] ([OrderId]),
    CONSTRAINT [FK_Complaints_UpdatedBy]  FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]  ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Complaints_UserId]
    ON [dbo].[Complaints] ([UserId] ASC, [CreatedAt] DESC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_Complaints_Status]
    ON [dbo].[Complaints] ([Status] ASC, [CreatedAt] DESC)
    WHERE [IsDeleted] = 0;
GO
