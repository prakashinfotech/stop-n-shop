CREATE TABLE [dbo].[Brands]
(
    [BrandId]         INT             NOT NULL  IDENTITY(1,1),
    [BrandName]       NVARCHAR(200)   NOT NULL,
    [SlugUrl]         NVARCHAR(300)   NOT NULL,
    [LogoUrl]         NVARCHAR(500)   NULL,
    [BannerUrl]       NVARCHAR(500)   NULL,
    [Description]     NVARCHAR(MAX)   NULL,
    [TagLine]         NVARCHAR(300)   NULL,
    [IsFeatured]      BIT             NOT NULL  CONSTRAINT [DF_Brands_IsFeatured]        DEFAULT 0,
    [SortOrder]       INT             NOT NULL  CONSTRAINT [DF_Brands_SortOrder]         DEFAULT 0,
    [MetaTitle]       NVARCHAR(200)   NULL,
    [MetaDescription] NVARCHAR(500)   NULL,
    [MetaKeywords]    NVARCHAR(500)   NULL,

    [CreatedAt]       DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Brands_CreatedAt]         DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Brands_UpdatedAt]         DEFAULT GETUTCDATE(),
    [CreatedBy]       INT             NULL,
    [UpdatedBy]       INT             NULL,
    [IsActive]        BIT             NOT NULL  CONSTRAINT [DF_Brands_IsActive]          DEFAULT 1,
    [IsDeleted]       BIT             NOT NULL  CONSTRAINT [DF_Brands_IsDeleted]         DEFAULT 0,

    CONSTRAINT [PK_Brands]            PRIMARY KEY CLUSTERED ([BrandId] ASC),
    CONSTRAINT [UQ_Brands_SlugUrl]    UNIQUE ([SlugUrl]),

    CONSTRAINT [FK_Brands_CreatedBy]  FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_Brands_UpdatedBy]  FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Brands_IsFeatured]
    ON [dbo].[Brands] ([IsFeatured] ASC, [SortOrder] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
