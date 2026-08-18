CREATE TABLE [dbo].[Banners]
(
    [BannerId]        INT            NOT NULL  IDENTITY(1,1),
    [Title]           NVARCHAR(300)  NOT NULL,
    [SubTitle]        NVARCHAR(500)  NULL,
    [ImageUrl]        NVARCHAR(500)  NOT NULL,
    [MobileImageUrl]  NVARCHAR(500)  NULL,
    [LinkUrl]         NVARCHAR(500)  NULL,
    [LinkTarget]      NVARCHAR(10)   NOT NULL  CONSTRAINT [DF_Banners_LinkTarget]  DEFAULT N'_self',
    [BannerType]      TINYINT        NOT NULL  CONSTRAINT [DF_Banners_BannerType]   DEFAULT 1,  -- 1=Hero, 2=Promotional, 3=Brand, 4=Category
    [EntityId]        INT            NULL,
    [SortOrder]       INT            NOT NULL  CONSTRAINT [DF_Banners_SortOrder]   DEFAULT 0,
    [StartDate]       DATETIME2(0)   NULL,
    [EndDate]         DATETIME2(0)   NULL,

    -- Admin-controlled visual rhythm: gap below this banner (px) + optional surrounding bg colour.
    -- Lets the CMS author tune the home-page banner stack without a deploy.
    [GapBelowPx]      INT            NOT NULL  CONSTRAINT [DF_Banners_GapBelowPx]   DEFAULT 32,
    [BackgroundColor] NVARCHAR(20)   NULL,

    [CreatedAt]       DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Banners_CreatedAt]   DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Banners_UpdatedAt]   DEFAULT GETUTCDATE(),
    [CreatedBy]       INT            NULL,
    [UpdatedBy]       INT            NULL,
    [IsActive]        BIT            NOT NULL  CONSTRAINT [DF_Banners_IsActive]    DEFAULT 1,
    [IsDeleted]       BIT            NOT NULL  CONSTRAINT [DF_Banners_IsDeleted]   DEFAULT 0,

    CONSTRAINT [PK_Banners]              PRIMARY KEY CLUSTERED ([BannerId] ASC),
    CONSTRAINT [CK_Banners_BannerType]   CHECK ([BannerType] BETWEEN 1 AND 7),

    CONSTRAINT [FK_Banners_CreatedBy]    FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_Banners_UpdatedBy]    FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Banners_Active]
    ON [dbo].[Banners] ([BannerType] ASC, [SortOrder] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
