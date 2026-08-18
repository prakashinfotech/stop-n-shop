CREATE TABLE [dbo].[Categories]
(
    [CategoryId]      INT            NOT NULL  IDENTITY(1,1),
    [MenuId]          INT            NOT NULL  CONSTRAINT [DF_Categories_MenuId] DEFAULT 1,
    [CategoryName]    NVARCHAR(200)  NOT NULL,
    [SlugUrl]         NVARCHAR(300)  NOT NULL,
    [IconUrl]         NVARCHAR(500)  NULL,
    [BannerUrl]       NVARCHAR(500)  NULL,
    [SortOrder]       INT            NOT NULL  CONSTRAINT [DF_Categories_SortOrder]  DEFAULT 0,
    [IsFeatured]      BIT            NOT NULL  CONSTRAINT [DF_Categories_IsFeatured] DEFAULT 0,
    [ShowInMegaMenu]  BIT            NOT NULL  CONSTRAINT [DF_Categories_ShowInMegaMenu] DEFAULT 1,
    [MetaTitle]       NVARCHAR(200)  NULL,
    [MetaDescription] NVARCHAR(500)  NULL,

    [CreatedAt]       DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Categories_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Categories_UpdatedAt]  DEFAULT GETUTCDATE(),
    [CreatedBy]       INT            NULL,
    [UpdatedBy]       INT            NULL,
    [IsActive]        BIT            NOT NULL  CONSTRAINT [DF_Categories_IsActive]   DEFAULT 1,
    [IsDeleted]       BIT            NOT NULL  CONSTRAINT [DF_Categories_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_Categories]           PRIMARY KEY CLUSTERED ([CategoryId] ASC),
    CONSTRAINT [UQ_Categories_SlugUrl]   UNIQUE ([SlugUrl]),

    CONSTRAINT [FK_Categories_MenuId]    FOREIGN KEY ([MenuId])    REFERENCES [dbo].[Menus]        ([MenuId]),
    CONSTRAINT [FK_Categories_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]        ([UserId]),
    CONSTRAINT [FK_Categories_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]        ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Categories_MenuId]
    ON [dbo].[Categories] ([MenuId] ASC, [SortOrder] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
