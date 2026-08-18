CREATE TABLE [dbo].[FooterContent]
(
    [FooterId]     INT            NOT NULL  IDENTITY(1,1),
    [SectionLabel] NVARCHAR(200)  NOT NULL,
    [LinkLabel]    NVARCHAR(200)  NOT NULL,
    [LinkUrl]      NVARCHAR(500)  NOT NULL,
    [SortOrder]    INT            NOT NULL  CONSTRAINT [DF_FooterContent_SortOrder]     DEFAULT 0,
    [ColumnNumber] TINYINT        NOT NULL  CONSTRAINT [DF_FooterContent_ColumnNumber]  DEFAULT 1,

    [CreatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_FooterContent_CreatedAt]     DEFAULT GETUTCDATE(),
    [UpdatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_FooterContent_UpdatedAt]     DEFAULT GETUTCDATE(),
    [CreatedBy]    INT            NULL,
    [UpdatedBy]    INT            NULL,
    [IsActive]     BIT            NOT NULL  CONSTRAINT [DF_FooterContent_IsActive]      DEFAULT 1,
    [IsDeleted]    BIT            NOT NULL  CONSTRAINT [DF_FooterContent_IsDeleted]     DEFAULT 0,

    CONSTRAINT [PK_FooterContent]           PRIMARY KEY CLUSTERED ([FooterId] ASC),

    CONSTRAINT [FK_FooterContent_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_FooterContent_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_FooterContent_SortOrder]
    ON [dbo].[FooterContent] ([ColumnNumber] ASC, [SortOrder] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
