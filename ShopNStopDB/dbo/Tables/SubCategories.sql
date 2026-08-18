CREATE TABLE [dbo].[SubCategories]
(
    [SubCategoryId]   INT            NOT NULL  IDENTITY(1,1),
    [CategoryId]      INT            NOT NULL,
    [SubCategoryName] NVARCHAR(200)  NOT NULL,
    [SlugUrl]         NVARCHAR(300)  NOT NULL,
    [IconUrl]         NVARCHAR(500)  NULL,
    [SortOrder]       INT            NOT NULL  CONSTRAINT [DF_SubCategories_SortOrder]  DEFAULT 0,
    [IsFeatured]      BIT            NOT NULL  CONSTRAINT [DF_SubCategories_IsFeatured] DEFAULT 0,
    [ShowInMegaMenu]  BIT            NOT NULL  CONSTRAINT [DF_SubCategories_ShowInMegaMenu] DEFAULT 1,

    -- Product-form schema (drives seller add/edit wizard rendering)
    [ImageAngles]        NVARCHAR(200) NULL,    -- JSON array, e.g. ["front","back","left","right"] or ["single"]
    [SizeScale]          NVARCHAR(30)  NULL,    -- apparel | shoe-uk | shoe-eu | toy | none
    [RequiresGender]     BIT           NOT NULL CONSTRAINT [DF_SubCategories_RequiresGender]     DEFAULT 0,
    [RequiresDimensions] BIT           NOT NULL CONSTRAINT [DF_SubCategories_RequiresDimensions] DEFAULT 0,

    [MetaTitle]       NVARCHAR(200)  NULL,
    [MetaDescription] NVARCHAR(500)  NULL,

    [CreatedAt]       DATETIME2(0)   NOT NULL  CONSTRAINT [DF_SubCategories_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2(0)   NOT NULL  CONSTRAINT [DF_SubCategories_UpdatedAt]  DEFAULT GETUTCDATE(),
    [CreatedBy]       INT            NULL,
    [UpdatedBy]       INT            NULL,
    [IsActive]        BIT            NOT NULL  CONSTRAINT [DF_SubCategories_IsActive]   DEFAULT 1,
    [IsDeleted]       BIT            NOT NULL  CONSTRAINT [DF_SubCategories_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_SubCategories]                  PRIMARY KEY CLUSTERED ([SubCategoryId] ASC),
    CONSTRAINT [UQ_SubCategories_SlugUrl]           UNIQUE ([SlugUrl]),

    CONSTRAINT [FK_SubCategories_CategoryId]        FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[Categories] ([CategoryId]),
    CONSTRAINT [FK_SubCategories_CreatedBy]         FOREIGN KEY ([CreatedBy])  REFERENCES [dbo].[Users]      ([UserId]),
    CONSTRAINT [FK_SubCategories_UpdatedBy]         FOREIGN KEY ([UpdatedBy])  REFERENCES [dbo].[Users]      ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SubCategories_CategoryId]
    ON [dbo].[SubCategories] ([CategoryId] ASC, [SortOrder] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
