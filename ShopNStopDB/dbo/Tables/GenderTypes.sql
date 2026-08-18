CREATE TABLE [dbo].[GenderTypes]
(
    [GenderTypeId] TINYINT        NOT NULL,
    [Name]         NVARCHAR(50)   NOT NULL,

    [CreatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_GenderTypes_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_GenderTypes_UpdatedAt]  DEFAULT GETUTCDATE(),
    [CreatedBy]    INT            NULL,
    [UpdatedBy]    INT            NULL,
    [IsActive]     BIT            NOT NULL  CONSTRAINT [DF_GenderTypes_IsActive]   DEFAULT 1,
    [IsDeleted]    BIT            NOT NULL  CONSTRAINT [DF_GenderTypes_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_GenderTypes] PRIMARY KEY CLUSTERED ([GenderTypeId] ASC),

    CONSTRAINT [FK_GenderTypes_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_GenderTypes_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO
