CREATE TABLE [dbo].[HomeSections]
(
    [SectionId]   INT             NOT NULL  IDENTITY(1,1),
    [SectionName] NVARCHAR(200)   NOT NULL,
    [SectionType] TINYINT         NOT NULL,  -- 1=FeaturedBrands, 2=TrendingProducts, 3=ExclusiveOffers, 4=Custom
    [Title]       NVARCHAR(300)   NOT NULL,
    [SubTitle]    NVARCHAR(500)   NULL,
    [SortOrder]   INT             NOT NULL  CONSTRAINT [DF_HomeSections_SortOrder]    DEFAULT 0,
    [ItemsToShow] TINYINT         NOT NULL  CONSTRAINT [DF_HomeSections_ItemsToShow]  DEFAULT 8,
    [FilterJson]  NVARCHAR(MAX)   NULL,

    [CreatedAt]   DATETIME2(0)    NOT NULL  CONSTRAINT [DF_HomeSections_CreatedAt]    DEFAULT GETUTCDATE(),
    [UpdatedAt]   DATETIME2(0)    NOT NULL  CONSTRAINT [DF_HomeSections_UpdatedAt]    DEFAULT GETUTCDATE(),
    [CreatedBy]   INT             NULL,
    [UpdatedBy]   INT             NULL,
    [IsActive]    BIT             NOT NULL  CONSTRAINT [DF_HomeSections_IsActive]     DEFAULT 1,
    [IsDeleted]   BIT             NOT NULL  CONSTRAINT [DF_HomeSections_IsDeleted]    DEFAULT 0,

    CONSTRAINT [PK_HomeSections]              PRIMARY KEY CLUSTERED ([SectionId] ASC),
    CONSTRAINT [CK_HomeSections_SectionType]  CHECK ([SectionType] IN (1, 2, 3, 4)),

    CONSTRAINT [FK_HomeSections_CreatedBy]    FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_HomeSections_UpdatedBy]    FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO
