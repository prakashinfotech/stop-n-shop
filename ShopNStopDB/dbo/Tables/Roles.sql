CREATE TABLE [dbo].[Roles]
(
    [RoleId]      TINYINT        NOT NULL,
    [RoleName]    NVARCHAR(50)   NOT NULL,
    [Description] NVARCHAR(200)  NULL,

    [CreatedAt]   DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Roles_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt]   DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Roles_UpdatedAt]  DEFAULT GETUTCDATE(),
    [CreatedBy]   INT            NULL,
    [UpdatedBy]   INT            NULL,
    [IsActive]    BIT            NOT NULL  CONSTRAINT [DF_Roles_IsActive]   DEFAULT 1,
    [IsDeleted]   BIT            NOT NULL  CONSTRAINT [DF_Roles_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED ([RoleId] ASC),

    -- Circular FK resolved by DACPAC deployment engine (Users depends on Roles)
    CONSTRAINT [FK_Roles_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_Roles_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO
