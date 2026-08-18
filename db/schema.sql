USE [ShopNShop_db];
GO
IF fulltextserviceproperty(N'IsFulltextInstalled') = 1
    EXECUTE sp_fulltext_database 'enable';


GO
PRINT N'Creating Table [dbo].[AuditLogs]...';


GO
CREATE TABLE [dbo].[AuditLogs] (
    [AuditId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [TableName] NVARCHAR (100) NOT NULL,
    [RecordId]  INT            NOT NULL,
    [Action]    NVARCHAR (10)  NOT NULL,
    [OldValues] NVARCHAR (MAX) NULL,
    [NewValues] NVARCHAR (MAX) NULL,
    [ChangedBy] INT            NULL,
    [ChangedAt] DATETIME2 (0)  NOT NULL,
    [IpAddress] NVARCHAR (50)  NULL,
    CONSTRAINT [PK_AuditLogs] PRIMARY KEY CLUSTERED ([AuditId] ASC)
);


GO
PRINT N'Creating Index [dbo].[AuditLogs].[IX_AuditLogs_TableRecordId]...';


GO
CREATE NONCLUSTERED INDEX [IX_AuditLogs_TableRecordId]
    ON [dbo].[AuditLogs]([TableName] ASC, [RecordId] ASC, [ChangedAt] DESC);


GO
PRINT N'Creating Index [dbo].[AuditLogs].[IX_AuditLogs_ChangedAt]...';


GO
CREATE NONCLUSTERED INDEX [IX_AuditLogs_ChangedAt]
    ON [dbo].[AuditLogs]([ChangedAt] DESC);


GO
PRINT N'Creating Table [dbo].[BankOffers]...';


GO
CREATE TABLE [dbo].[BankOffers] (
    [BankOfferId] INT             IDENTITY (1, 1) NOT NULL,
    [Title]       NVARCHAR (300)  NOT NULL,
    [Description] NVARCHAR (MAX)  NULL,
    [MinSpend]    DECIMAL (18, 2) NULL,
    [MaxDiscount] DECIMAL (18, 2) NULL,
    [TermsUrl]    NVARCHAR (500)  NULL,
    [SortOrder]   INT             NOT NULL,
    [CreatedAt]   DATETIME2 (0)   NOT NULL,
    [UpdatedAt]   DATETIME2 (0)   NOT NULL,
    [IsActive]    BIT             NOT NULL,
    [IsDeleted]   BIT             NOT NULL,
    CONSTRAINT [PK_BankOffers] PRIMARY KEY CLUSTERED ([BankOfferId] ASC)
);


GO
PRINT N'Creating Index [dbo].[BankOffers].[IX_BankOffers_Active]...';


GO
CREATE NONCLUSTERED INDEX [IX_BankOffers_Active]
    ON [dbo].[BankOffers]([SortOrder] ASC) WHERE [IsDeleted] = 0 AND [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[Banners]...';


GO
CREATE TABLE [dbo].[Banners] (
    [BannerId]       INT            IDENTITY (1, 1) NOT NULL,
    [Title]          NVARCHAR (300) NOT NULL,
    [SubTitle]       NVARCHAR (500) NULL,
    [ImageUrl]       NVARCHAR (500) NOT NULL,
    [MobileImageUrl] NVARCHAR (500) NULL,
    [LinkUrl]        NVARCHAR (500) NULL,
    [LinkTarget]     NVARCHAR (10)  NOT NULL,
    [BannerType]     TINYINT        NOT NULL,
    [EntityId]       INT            NULL,
    [SortOrder]      INT            NOT NULL,
    [StartDate]      DATETIME2 (0)  NULL,
    [EndDate]        DATETIME2 (0)  NULL,
    [CreatedAt]      DATETIME2 (0)  NOT NULL,
    [UpdatedAt]      DATETIME2 (0)  NOT NULL,
    [CreatedBy]      INT            NULL,
    [UpdatedBy]      INT            NULL,
    [IsActive]       BIT            NOT NULL,
    [IsDeleted]      BIT            NOT NULL,
    CONSTRAINT [PK_Banners] PRIMARY KEY CLUSTERED ([BannerId] ASC)
);


GO
PRINT N'Creating Index [dbo].[Banners].[IX_Banners_Active]...';


GO
CREATE NONCLUSTERED INDEX [IX_Banners_Active]
    ON [dbo].[Banners]([BannerType] ASC, [SortOrder] ASC) WHERE [IsDeleted] = 0 AND [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[Brands]...';


GO
CREATE TABLE [dbo].[Brands] (
    [BrandId]         INT            IDENTITY (1, 1) NOT NULL,
    [BrandName]       NVARCHAR (200) NOT NULL,
    [SlugUrl]         NVARCHAR (300) NOT NULL,
    [LogoUrl]         NVARCHAR (500) NULL,
    [BannerUrl]       NVARCHAR (500) NULL,
    [Description]     NVARCHAR (MAX) NULL,
    [TagLine]         NVARCHAR (300) NULL,
    [IsFeatured]      BIT            NOT NULL,
    [SortOrder]       INT            NOT NULL,
    [MetaTitle]       NVARCHAR (200) NULL,
    [MetaDescription] NVARCHAR (500) NULL,
    [MetaKeywords]    NVARCHAR (500) NULL,
    [CreatedAt]       DATETIME2 (0)  NOT NULL,
    [UpdatedAt]       DATETIME2 (0)  NOT NULL,
    [CreatedBy]       INT            NULL,
    [UpdatedBy]       INT            NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_Brands] PRIMARY KEY CLUSTERED ([BrandId] ASC),
    CONSTRAINT [UQ_Brands_SlugUrl] UNIQUE NONCLUSTERED ([SlugUrl] ASC)
);


GO
PRINT N'Creating Index [dbo].[Brands].[IX_Brands_IsFeatured]...';


GO
CREATE NONCLUSTERED INDEX [IX_Brands_IsFeatured]
    ON [dbo].[Brands]([IsFeatured] ASC, [SortOrder] ASC) WHERE [IsDeleted] = 0 AND [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[Cart]...';


GO
CREATE TABLE [dbo].[Cart] (
    [CartId]        INT           IDENTITY (1, 1) NOT NULL,
    [UserId]        INT           NOT NULL,
    [ProductId]     INT           NOT NULL,
    [VariantId]     INT           NOT NULL,
    [Quantity]      INT           NOT NULL,
    [AddedAt]       DATETIME2 (0) NOT NULL,
    [SavedForLater] BIT           NOT NULL,
    [CreatedAt]     DATETIME2 (0) NOT NULL,
    [UpdatedAt]     DATETIME2 (0) NOT NULL,
    [CreatedBy]     INT           NULL,
    [UpdatedBy]     INT           NULL,
    [IsActive]      BIT           NOT NULL,
    [IsDeleted]     BIT           NOT NULL,
    CONSTRAINT [PK_Cart] PRIMARY KEY CLUSTERED ([CartId] ASC),
    CONSTRAINT [UQ_Cart_UserVariant] UNIQUE NONCLUSTERED ([UserId] ASC, [VariantId] ASC)
);


GO
PRINT N'Creating Index [dbo].[Cart].[IX_Cart_UserId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Cart_UserId]
    ON [dbo].[Cart]([UserId] ASC, [SavedForLater] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[Categories]...';


GO
CREATE TABLE [dbo].[Categories] (
    [CategoryId]      INT            IDENTITY (1, 1) NOT NULL,
    [MenuId]          INT            NOT NULL,
    [CategoryName]    NVARCHAR (200) NOT NULL,
    [SlugUrl]         NVARCHAR (300) NOT NULL,
    [IconUrl]         NVARCHAR (500) NULL,
    [BannerUrl]       NVARCHAR (500) NULL,
    [SortOrder]       INT            NOT NULL,
    [IsFeatured]      BIT            NOT NULL,
    [MetaTitle]       NVARCHAR (200) NULL,
    [MetaDescription] NVARCHAR (500) NULL,
    [CreatedAt]       DATETIME2 (0)  NOT NULL,
    [UpdatedAt]       DATETIME2 (0)  NOT NULL,
    [CreatedBy]       INT            NULL,
    [UpdatedBy]       INT            NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED ([CategoryId] ASC),
    CONSTRAINT [UQ_Categories_SlugUrl] UNIQUE NONCLUSTERED ([SlugUrl] ASC)
);


GO
PRINT N'Creating Index [dbo].[Categories].[IX_Categories_MenuId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Categories_MenuId]
    ON [dbo].[Categories]([MenuId] ASC, [SortOrder] ASC) WHERE [IsDeleted] = 0 AND [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[Coupons]...';


GO
CREATE TABLE [dbo].[Coupons] (
    [CouponId]   INT           IDENTITY (1, 1) NOT NULL,
    [CouponCode] NVARCHAR (50) NOT NULL,
    [OfferId]    INT           NOT NULL,
    [CreatedAt]  DATETIME2 (0) NOT NULL,
    [UpdatedAt]  DATETIME2 (0) NOT NULL,
    [CreatedBy]  INT           NULL,
    [UpdatedBy]  INT           NULL,
    [IsActive]   BIT           NOT NULL,
    [IsDeleted]  BIT           NOT NULL,
    CONSTRAINT [PK_Coupons] PRIMARY KEY CLUSTERED ([CouponId] ASC),
    CONSTRAINT [UQ_Coupons_CouponCode] UNIQUE NONCLUSTERED ([CouponCode] ASC)
);


GO
PRINT N'Creating Table [dbo].[FooterContent]...';


GO
CREATE TABLE [dbo].[FooterContent] (
    [FooterId]     INT            IDENTITY (1, 1) NOT NULL,
    [SectionLabel] NVARCHAR (200) NOT NULL,
    [LinkLabel]    NVARCHAR (200) NOT NULL,
    [LinkUrl]      NVARCHAR (500) NOT NULL,
    [SortOrder]    INT            NOT NULL,
    [ColumnNumber] TINYINT        NOT NULL,
    [CreatedAt]    DATETIME2 (0)  NOT NULL,
    [UpdatedAt]    DATETIME2 (0)  NOT NULL,
    [CreatedBy]    INT            NULL,
    [UpdatedBy]    INT            NULL,
    [IsActive]     BIT            NOT NULL,
    [IsDeleted]    BIT            NOT NULL,
    CONSTRAINT [PK_FooterContent] PRIMARY KEY CLUSTERED ([FooterId] ASC)
);


GO
PRINT N'Creating Index [dbo].[FooterContent].[IX_FooterContent_SortOrder]...';


GO
CREATE NONCLUSTERED INDEX [IX_FooterContent_SortOrder]
    ON [dbo].[FooterContent]([ColumnNumber] ASC, [SortOrder] ASC) WHERE [IsDeleted] = 0 AND [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[GenderTypes]...';


GO
CREATE TABLE [dbo].[GenderTypes] (
    [GenderTypeId] TINYINT       NOT NULL,
    [Name]         NVARCHAR (50) NOT NULL,
    [CreatedAt]    DATETIME2 (0) NOT NULL,
    [UpdatedAt]    DATETIME2 (0) NOT NULL,
    [CreatedBy]    INT           NULL,
    [UpdatedBy]    INT           NULL,
    [IsActive]     BIT           NOT NULL,
    [IsDeleted]    BIT           NOT NULL,
    CONSTRAINT [PK_GenderTypes] PRIMARY KEY CLUSTERED ([GenderTypeId] ASC)
);


GO
PRINT N'Creating Table [dbo].[HomeSections]...';


GO
CREATE TABLE [dbo].[HomeSections] (
    [SectionId]   INT            IDENTITY (1, 1) NOT NULL,
    [SectionName] NVARCHAR (200) NOT NULL,
    [SectionType] TINYINT        NOT NULL,
    [Title]       NVARCHAR (300) NOT NULL,
    [SubTitle]    NVARCHAR (500) NULL,
    [SortOrder]   INT            NOT NULL,
    [ItemsToShow] TINYINT        NOT NULL,
    [FilterJson]  NVARCHAR (MAX) NULL,
    [CreatedAt]   DATETIME2 (0)  NOT NULL,
    [UpdatedAt]   DATETIME2 (0)  NOT NULL,
    [CreatedBy]   INT            NULL,
    [UpdatedBy]   INT            NULL,
    [IsActive]    BIT            NOT NULL,
    [IsDeleted]   BIT            NOT NULL,
    CONSTRAINT [PK_HomeSections] PRIMARY KEY CLUSTERED ([SectionId] ASC)
);


GO
PRINT N'Creating Table [dbo].[Menus]...';


GO
CREATE TABLE [dbo].[Menus] (
    [MenuId]    INT            IDENTITY (1, 1) NOT NULL,
    [MenuName]  NVARCHAR (100) NOT NULL,
    [SlugUrl]   NVARCHAR (200) NOT NULL,
    [SortOrder] INT            NOT NULL,
    [IsActive]  BIT            NOT NULL,
    [IsDeleted] BIT            NOT NULL,
    [CreatedAt] DATETIME2 (0)  NOT NULL,
    CONSTRAINT [PK_Menus] PRIMARY KEY CLUSTERED ([MenuId] ASC),
    CONSTRAINT [UQ_Menus_SlugUrl] UNIQUE NONCLUSTERED ([SlugUrl] ASC)
);


GO
PRINT N'Creating Table [dbo].[Notifications]...';


GO
CREATE TABLE [dbo].[Notifications] (
    [NotificationId]   INT             IDENTITY (1, 1) NOT NULL,
    [UserId]           INT             NOT NULL,
    [Title]            NVARCHAR (300)  NOT NULL,
    [Body]             NVARCHAR (1000) NOT NULL,
    [NotificationType] TINYINT         NOT NULL,
    [EntityType]       NVARCHAR (50)   NULL,
    [EntityId]         INT             NULL,
    [IsRead]           BIT             NOT NULL,
    [ReadAt]           DATETIME2 (0)   NULL,
    [Channel]          TINYINT         NOT NULL,
    [SentAt]           DATETIME2 (0)   NULL,
    [CreatedAt]        DATETIME2 (0)   NOT NULL,
    [IsDeleted]        BIT             NOT NULL,
    CONSTRAINT [PK_Notifications] PRIMARY KEY CLUSTERED ([NotificationId] ASC)
);


GO
PRINT N'Creating Index [dbo].[Notifications].[IX_Notifications_UserId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Notifications_UserId]
    ON [dbo].[Notifications]([UserId] ASC, [IsRead] ASC, [CreatedAt] DESC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[Offers]...';


GO
CREATE TABLE [dbo].[Offers] (
    [OfferId]           INT             IDENTITY (1, 1) NOT NULL,
    [OfferName]         NVARCHAR (300)  NOT NULL,
    [OfferType]         TINYINT         NOT NULL,
    [DiscountValue]     DECIMAL (18, 2) NOT NULL,
    [MinOrderValue]     DECIMAL (18, 2) NOT NULL,
    [MaxDiscountCap]    DECIMAL (18, 2) NULL,
    [StartDate]         DATETIME2 (0)   NOT NULL,
    [EndDate]           DATETIME2 (0)   NOT NULL,
    [ApplicableOn]      TINYINT         NOT NULL,
    [EntityId]          INT             NULL,
    [UsageLimitTotal]   INT             NULL,
    [UsageLimitPerUser] TINYINT         NOT NULL,
    [CurrentUsageCount] INT             NOT NULL,
    [CreatedAt]         DATETIME2 (0)   NOT NULL,
    [UpdatedAt]         DATETIME2 (0)   NOT NULL,
    [CreatedBy]         INT             NULL,
    [UpdatedBy]         INT             NULL,
    [IsActive]          BIT             NOT NULL,
    [IsDeleted]         BIT             NOT NULL,
    CONSTRAINT [PK_Offers] PRIMARY KEY CLUSTERED ([OfferId] ASC)
);


GO
PRINT N'Creating Index [dbo].[Offers].[IX_Offers_ActiveDate]...';


GO
CREATE NONCLUSTERED INDEX [IX_Offers_ActiveDate]
    ON [dbo].[Offers]([StartDate] ASC, [EndDate] ASC, [ApplicableOn] ASC) WHERE [IsDeleted] = 0 AND [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[OrderItems]...';


GO
CREATE TABLE [dbo].[OrderItems] (
    [OrderItemId]          INT             IDENTITY (1, 1) NOT NULL,
    [OrderId]              INT             NOT NULL,
    [ProductId]            INT             NOT NULL,
    [VariantId]            INT             NOT NULL,
    [SellerId]             INT             NOT NULL,
    [BrandId]              INT             NOT NULL,
    [ProductName]          NVARCHAR (300)  NOT NULL,
    [VariantSnapshot]      NVARCHAR (300)  NULL,
    [Quantity]             INT             NOT NULL,
    [UnitPrice]            DECIMAL (18, 2) NOT NULL,
    [DiscountAmount]       DECIMAL (18, 2) NOT NULL,
    [TaxAmount]            DECIMAL (18, 2) NOT NULL,
    [TotalPrice]           DECIMAL (18, 2) NOT NULL,
    [SellerCommissionRate] DECIMAL (5, 2)  NULL,
    [CommissionAmount]     DECIMAL (18, 2) NULL,
    [SellerEarning]        DECIMAL (18, 2) NULL,
    [IsReturned]           BIT             NOT NULL,
    [ReturnReason]         NVARCHAR (500)  NULL,
    [CreatedAt]            DATETIME2 (0)   NOT NULL,
    [UpdatedAt]            DATETIME2 (0)   NOT NULL,
    [CreatedBy]            INT             NULL,
    [UpdatedBy]            INT             NULL,
    [IsActive]             BIT             NOT NULL,
    [IsDeleted]            BIT             NOT NULL,
    CONSTRAINT [PK_OrderItems] PRIMARY KEY CLUSTERED ([OrderItemId] ASC)
);


GO
PRINT N'Creating Index [dbo].[OrderItems].[IX_OrderItems_OrderId]...';


GO
CREATE NONCLUSTERED INDEX [IX_OrderItems_OrderId]
    ON [dbo].[OrderItems]([OrderId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Index [dbo].[OrderItems].[IX_OrderItems_SellerId]...';


GO
CREATE NONCLUSTERED INDEX [IX_OrderItems_SellerId]
    ON [dbo].[OrderItems]([SellerId] ASC, [CreatedAt] DESC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[Orders]...';


GO
CREATE TABLE [dbo].[Orders] (
    [OrderId]                INT             IDENTITY (1, 1) NOT NULL,
    [UserId]                 INT             NOT NULL,
    [OrderNumber]            NVARCHAR (50)   NOT NULL,
    [OrderStatus]            TINYINT         NOT NULL,
    [SubTotal]               DECIMAL (18, 2) NOT NULL,
    [DiscountAmount]         DECIMAL (18, 2) NOT NULL,
    [CouponId]               INT             NULL,
    [CouponDiscount]         DECIMAL (18, 2) NOT NULL,
    [TaxAmount]              DECIMAL (18, 2) NOT NULL,
    [ShippingCharge]         DECIMAL (18, 2) NOT NULL,
    [TotalAmount]            DECIMAL (18, 2) NOT NULL,
    [ShippingAddressId]      INT             NOT NULL,
    [PaymentMode]            TINYINT         NOT NULL,
    [PaymentStatus]          TINYINT         NOT NULL,
    [PaymentGatewayRef]      NVARCHAR (200)  NULL,
    [PaymentGatewayResponse] NVARCHAR (MAX)  NULL,
    [ExpectedDeliveryDate]   DATE            NULL,
    [DeliveredAt]            DATETIME2 (0)   NULL,
    [CancelledAt]            DATETIME2 (0)   NULL,
    [CancellationReason]     NVARCHAR (500)  NULL,
    [EmailSentAt]            DATETIME2 (0)   NULL,
    [SmsSentAt]              DATETIME2 (0)   NULL,
    [CreatedAt]              DATETIME2 (0)   NOT NULL,
    [UpdatedAt]              DATETIME2 (0)   NOT NULL,
    [CreatedBy]              INT             NULL,
    [UpdatedBy]              INT             NULL,
    [IsActive]               BIT             NOT NULL,
    [IsDeleted]              BIT             NOT NULL,
    CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED ([OrderId] ASC),
    CONSTRAINT [UQ_Orders_OrderNumber] UNIQUE NONCLUSTERED ([OrderNumber] ASC)
);


GO
PRINT N'Creating Index [dbo].[Orders].[IX_Orders_UserId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Orders_UserId]
    ON [dbo].[Orders]([UserId] ASC, [OrderStatus] ASC, [CreatedAt] DESC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Index [dbo].[Orders].[IX_Orders_OrderStatus]...';


GO
CREATE NONCLUSTERED INDEX [IX_Orders_OrderStatus]
    ON [dbo].[Orders]([OrderStatus] ASC, [CreatedAt] DESC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[OtpVerifications]...';


GO
CREATE TABLE [dbo].[OtpVerifications] (
    [OtpId]        INT           IDENTITY (1, 1) NOT NULL,
    [UserId]       INT           NOT NULL,
    [OtpCode]      NVARCHAR (10) NOT NULL,
    [OtpType]      TINYINT       NOT NULL,
    [ExpiresAt]    DATETIME2 (0) NOT NULL,
    [IsUsed]       BIT           NOT NULL,
    [AttemptCount] TINYINT       NOT NULL,
    [CreatedAt]    DATETIME2 (0) NOT NULL,
    [IsDeleted]    BIT           NOT NULL,
    CONSTRAINT [PK_OtpVerifications] PRIMARY KEY CLUSTERED ([OtpId] ASC)
);


GO
PRINT N'Creating Index [dbo].[OtpVerifications].[IX_OtpVerifications_UserId_OtpType]...';


GO
CREATE NONCLUSTERED INDEX [IX_OtpVerifications_UserId_OtpType]
    ON [dbo].[OtpVerifications]([UserId] ASC, [OtpType] ASC, [IsUsed] ASC, [IsDeleted] ASC);


GO
PRINT N'Creating Table [dbo].[Pincodes]...';


GO
CREATE TABLE [dbo].[Pincodes] (
    [Pincode]       NVARCHAR (10)  NOT NULL,
    [City]          NVARCHAR (100) NOT NULL,
    [State]         NVARCHAR (100) NOT NULL,
    [EstimatedDays] TINYINT        NOT NULL,
    [CODAvailable]  BIT            NOT NULL,
    [IsActive]      BIT            NOT NULL,
    [CreatedAt]     DATETIME2 (0)  NOT NULL,
    [UpdatedAt]     DATETIME2 (0)  NOT NULL,
    CONSTRAINT [PK_Pincodes] PRIMARY KEY CLUSTERED ([Pincode] ASC)
);


GO
PRINT N'Creating Index [dbo].[Pincodes].[IX_Pincodes_CityState]...';


GO
CREATE NONCLUSTERED INDEX [IX_Pincodes_CityState]
    ON [dbo].[Pincodes]([City] ASC, [State] ASC) WHERE [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[PriceHistory]...';


GO
CREATE TABLE [dbo].[PriceHistory] (
    [HistoryId]       INT             IDENTITY (1, 1) NOT NULL,
    [ProductId]       INT             NOT NULL,
    [OldMRP]          DECIMAL (18, 2) NOT NULL,
    [NewMRP]          DECIMAL (18, 2) NOT NULL,
    [OldSellingPrice] DECIMAL (18, 2) NOT NULL,
    [NewSellingPrice] DECIMAL (18, 2) NOT NULL,
    [ChangedBy]       INT             NOT NULL,
    [ChangedAt]       DATETIME2 (0)   NOT NULL,
    [Reason]          NVARCHAR (500)  NULL,
    CONSTRAINT [PK_PriceHistory] PRIMARY KEY CLUSTERED ([HistoryId] ASC)
);


GO
PRINT N'Creating Index [dbo].[PriceHistory].[IX_PriceHistory_ProductId]...';


GO
CREATE NONCLUSTERED INDEX [IX_PriceHistory_ProductId]
    ON [dbo].[PriceHistory]([ProductId] ASC, [ChangedAt] DESC);


GO
PRINT N'Creating Table [dbo].[ProductImages]...';


GO
CREATE TABLE [dbo].[ProductImages] (
    [ImageId]   INT            IDENTITY (1, 1) NOT NULL,
    [ProductId] INT            NOT NULL,
    [VariantId] INT            NULL,
    [ImageUrl]  NVARCHAR (500) NOT NULL,
    [AltText]   NVARCHAR (300) NULL,
    [SortOrder] INT            NOT NULL,
    [IsPrimary] BIT            NOT NULL,
    [CreatedAt] DATETIME2 (0)  NOT NULL,
    [UpdatedAt] DATETIME2 (0)  NOT NULL,
    [CreatedBy] INT            NULL,
    [UpdatedBy] INT            NULL,
    [IsActive]  BIT            NOT NULL,
    [IsDeleted] BIT            NOT NULL,
    CONSTRAINT [PK_ProductImages] PRIMARY KEY CLUSTERED ([ImageId] ASC)
);


GO
PRINT N'Creating Index [dbo].[ProductImages].[IX_ProductImages_ProductId]...';


GO
CREATE NONCLUSTERED INDEX [IX_ProductImages_ProductId]
    ON [dbo].[ProductImages]([ProductId] ASC, [SortOrder] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[Products]...';


GO
CREATE TABLE [dbo].[Products] (
    [ProductId]        INT             IDENTITY (1, 1) NOT NULL,
    [SellerId]         INT             NOT NULL,
    [BrandId]          INT             NOT NULL,
    [CategoryId]       INT             NOT NULL,
    [SubCategoryId]    INT             NOT NULL,
    [ProductName]      NVARCHAR (300)  NOT NULL,
    [SlugUrl]          NVARCHAR (400)  NOT NULL,
    [ShortDescription] NVARCHAR (500)  NULL,
    [LongDescription]  NVARCHAR (MAX)  NULL,
    [MRP]              DECIMAL (18, 2) NOT NULL,
    [SellingPrice]     DECIMAL (18, 2) NOT NULL,
    [CostPrice]        DECIMAL (18, 2) NULL,
    [GstRate]          DECIMAL (5, 2)  NOT NULL,
    [Sku]              NVARCHAR (100)  NULL,
    [GenderTypeId]     TINYINT         NULL,
    [IsReturnable]     BIT             NOT NULL,
    [ReturnWindowDays] TINYINT         NOT NULL,
    [IsCODAvailable]   BIT             NOT NULL,
    [Tags]             NVARCHAR (1000) NULL,
    [AITagJson]        NVARCHAR (MAX)  NULL,
    [IsFeatured]       BIT             NOT NULL,
    [SortOrder]        INT             NOT NULL,
    [MetaTitle]        NVARCHAR (200)  NULL,
    [MetaDescription]  NVARCHAR (500)  NULL,
    [MetaKeywords]     NVARCHAR (500)  NULL,
    [ApprovalStatus]   TINYINT         NOT NULL,
    [ApprovedBy]       INT             NULL,
    [ApprovedAt]       DATETIME2 (0)   NULL,
    [PublishedAt]      DATETIME2 (0)   NULL,
    [RejectionReason]  NVARCHAR (500)  NULL,
    [Material]         NVARCHAR (200)  NULL,
    [CareInstructions] NVARCHAR (500)  NULL,
    [FitType]          NVARCHAR (50)   NULL,
    [CountryOfOrigin]  NVARCHAR (100)  NULL,
    [WarrantyInfo]     NVARCHAR (500)  NULL,
    [DeliveryInfo]     NVARCHAR (500)  NULL,
    [CreatedAt]        DATETIME2 (0)   NOT NULL,
    [UpdatedAt]        DATETIME2 (0)   NOT NULL,
    [CreatedBy]        INT             NULL,
    [UpdatedBy]        INT             NULL,
    [IsActive]         BIT             NOT NULL,
    [IsDeleted]        BIT             NOT NULL,
    CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED ([ProductId] ASC),
    CONSTRAINT [UQ_Products_Sku] UNIQUE NONCLUSTERED ([Sku] ASC),
    CONSTRAINT [UQ_Products_SlugUrl] UNIQUE NONCLUSTERED ([SlugUrl] ASC)
);


GO
PRINT N'Creating Index [dbo].[Products].[IX_Products_SellerId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Products_SellerId]
    ON [dbo].[Products]([SellerId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Index [dbo].[Products].[IX_Products_BrandId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Products_BrandId]
    ON [dbo].[Products]([BrandId] ASC, [ApprovalStatus] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Index [dbo].[Products].[IX_Products_CategoryId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Products_CategoryId]
    ON [dbo].[Products]([CategoryId] ASC, [SubCategoryId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Index [dbo].[Products].[IX_Products_GenderTypeId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Products_GenderTypeId]
    ON [dbo].[Products]([GenderTypeId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Index [dbo].[Products].[IX_Products_ApprovalStatus]...';


GO
CREATE NONCLUSTERED INDEX [IX_Products_ApprovalStatus]
    ON [dbo].[Products]([ApprovalStatus] ASC, [IsActive] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[ProductSpecifications]...';


GO
CREATE TABLE [dbo].[ProductSpecifications] (
    [SpecId]    INT            IDENTITY (1, 1) NOT NULL,
    [ProductId] INT            NOT NULL,
    [SpecKey]   NVARCHAR (200) NOT NULL,
    [SpecValue] NVARCHAR (500) NOT NULL,
    [SortOrder] INT            NOT NULL,
    [CreatedAt] DATETIME2 (0)  NOT NULL,
    [IsDeleted] BIT            NOT NULL,
    CONSTRAINT [PK_ProductSpecifications] PRIMARY KEY CLUSTERED ([SpecId] ASC)
);


GO
PRINT N'Creating Index [dbo].[ProductSpecifications].[IX_ProductSpecifications_ProductId]...';


GO
CREATE NONCLUSTERED INDEX [IX_ProductSpecifications_ProductId]
    ON [dbo].[ProductSpecifications]([ProductId] ASC, [SortOrder] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[ProductSubCategories]...';


GO
CREATE TABLE [dbo].[ProductSubCategories] (
    [ProductId]     INT           NOT NULL,
    [SubCategoryId] INT           NOT NULL,
    [CreatedAt]     DATETIME2 (0) NOT NULL,
    CONSTRAINT [PK_ProductSubCategories] PRIMARY KEY CLUSTERED ([ProductId] ASC, [SubCategoryId] ASC)
);


GO
PRINT N'Creating Index [dbo].[ProductSubCategories].[IX_PSC_SubCategoryId]...';


GO
CREATE NONCLUSTERED INDEX [IX_PSC_SubCategoryId]
    ON [dbo].[ProductSubCategories]([SubCategoryId] ASC)
    INCLUDE([ProductId]);


GO
PRINT N'Creating Table [dbo].[ProductVariants]...';


GO
CREATE TABLE [dbo].[ProductVariants] (
    [VariantId]         INT             IDENTITY (1, 1) NOT NULL,
    [ProductId]         INT             NOT NULL,
    [Color]             NVARCHAR (100)  NULL,
    [ColorHexCode]      NVARCHAR (10)   NULL,
    [Size]              NVARCHAR (50)   NULL,
    [Material]          NVARCHAR (100)  NULL,
    [Pattern]           NVARCHAR (100)  NULL,
    [FitType]           NVARCHAR (100)  NULL,
    [VariantSku]        NVARCHAR (150)  NOT NULL,
    [AdditionalPrice]   DECIMAL (18, 2) NOT NULL,
    [StockQuantity]     INT             NOT NULL,
    [LowStockThreshold] INT             NOT NULL,
    [Weight]            DECIMAL (10, 3) NULL,
    [Dimensions]        NVARCHAR (100)  NULL,
    [BarCode]           NVARCHAR (100)  NULL,
    [CreatedAt]         DATETIME2 (0)   NOT NULL,
    [UpdatedAt]         DATETIME2 (0)   NOT NULL,
    [CreatedBy]         INT             NULL,
    [UpdatedBy]         INT             NULL,
    [IsActive]          BIT             NOT NULL,
    [IsDeleted]         BIT             NOT NULL,
    CONSTRAINT [PK_ProductVariants] PRIMARY KEY CLUSTERED ([VariantId] ASC),
    CONSTRAINT [UQ_ProductVariants_VariantSku] UNIQUE NONCLUSTERED ([VariantSku] ASC)
);


GO
PRINT N'Creating Index [dbo].[ProductVariants].[IX_ProductVariants_ProductId]...';


GO
CREATE NONCLUSTERED INDEX [IX_ProductVariants_ProductId]
    ON [dbo].[ProductVariants]([ProductId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Index [dbo].[ProductVariants].[IX_ProductVariants_StockQuantity]...';


GO
CREATE NONCLUSTERED INDEX [IX_ProductVariants_StockQuantity]
    ON [dbo].[ProductVariants]([ProductId] ASC, [StockQuantity] ASC) WHERE [IsDeleted] = 0 AND [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[ProductViewLogs]...';


GO
CREATE TABLE [dbo].[ProductViewLogs] (
    [LogId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [ProductId]  INT            NOT NULL,
    [UserId]     INT            NULL,
    [SessionId]  NVARCHAR (100) NULL,
    [IpAddress]  NVARCHAR (50)  NULL,
    [DeviceType] NVARCHAR (50)  NULL,
    [ViewedAt]   DATETIME2 (0)  NOT NULL,
    CONSTRAINT [PK_ProductViewLogs] PRIMARY KEY CLUSTERED ([LogId] ASC)
);


GO
PRINT N'Creating Index [dbo].[ProductViewLogs].[IX_ProductViewLogs_ProductId]...';


GO
CREATE NONCLUSTERED INDEX [IX_ProductViewLogs_ProductId]
    ON [dbo].[ProductViewLogs]([ProductId] ASC, [ViewedAt] DESC);


GO
PRINT N'Creating Index [dbo].[ProductViewLogs].[IX_ProductViewLogs_ViewedAt]...';


GO
CREATE NONCLUSTERED INDEX [IX_ProductViewLogs_ViewedAt]
    ON [dbo].[ProductViewLogs]([ViewedAt] DESC);


GO
PRINT N'Creating Table [dbo].[RecentlyViewed]...';


GO
CREATE TABLE [dbo].[RecentlyViewed] (
    [ViewId]    INT           IDENTITY (1, 1) NOT NULL,
    [UserId]    INT           NOT NULL,
    [ProductId] INT           NOT NULL,
    [ViewedAt]  DATETIME2 (0) NOT NULL,
    [CreatedAt] DATETIME2 (0) NOT NULL,
    [UpdatedAt] DATETIME2 (0) NOT NULL,
    [IsDeleted] BIT           NOT NULL,
    CONSTRAINT [PK_RecentlyViewed] PRIMARY KEY CLUSTERED ([ViewId] ASC),
    CONSTRAINT [UQ_RecentlyViewed_UserProduct] UNIQUE NONCLUSTERED ([UserId] ASC, [ProductId] ASC)
);


GO
PRINT N'Creating Index [dbo].[RecentlyViewed].[IX_RecentlyViewed_UserId]...';


GO
CREATE NONCLUSTERED INDEX [IX_RecentlyViewed_UserId]
    ON [dbo].[RecentlyViewed]([UserId] ASC, [ViewedAt] DESC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[RefreshTokens]...';


GO
CREATE TABLE [dbo].[RefreshTokens] (
    [TokenId]    INT            IDENTITY (1, 1) NOT NULL,
    [UserId]     INT            NOT NULL,
    [Token]      NVARCHAR (500) NOT NULL,
    [ExpiresAt]  DATETIME2 (0)  NOT NULL,
    [IsRevoked]  BIT            NOT NULL,
    [DeviceInfo] NVARCHAR (300) NULL,
    [IpAddress]  NVARCHAR (50)  NULL,
    [CreatedAt]  DATETIME2 (0)  NOT NULL,
    CONSTRAINT [PK_RefreshTokens] PRIMARY KEY CLUSTERED ([TokenId] ASC),
    CONSTRAINT [UQ_RefreshTokens_Token] UNIQUE NONCLUSTERED ([Token] ASC)
);


GO
PRINT N'Creating Index [dbo].[RefreshTokens].[IX_RefreshTokens_UserId_IsRevoked]...';


GO
CREATE NONCLUSTERED INDEX [IX_RefreshTokens_UserId_IsRevoked]
    ON [dbo].[RefreshTokens]([UserId] ASC, [IsRevoked] ASC, [ExpiresAt] ASC);


GO
PRINT N'Creating Table [dbo].[ReviewImages]...';


GO
CREATE TABLE [dbo].[ReviewImages] (
    [ReviewImageId] INT            IDENTITY (1, 1) NOT NULL,
    [ReviewId]      INT            NOT NULL,
    [ImageUrl]      NVARCHAR (500) NOT NULL,
    [CreatedAt]     DATETIME2 (0)  NOT NULL,
    [IsDeleted]     BIT            NOT NULL,
    CONSTRAINT [PK_ReviewImages] PRIMARY KEY CLUSTERED ([ReviewImageId] ASC)
);


GO
PRINT N'Creating Index [dbo].[ReviewImages].[IX_ReviewImages_ReviewId]...';


GO
CREATE NONCLUSTERED INDEX [IX_ReviewImages_ReviewId]
    ON [dbo].[ReviewImages]([ReviewId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[Reviews]...';


GO
CREATE TABLE [dbo].[Reviews] (
    [ReviewId]           INT             IDENTITY (1, 1) NOT NULL,
    [ProductId]          INT             NOT NULL,
    [UserId]             INT             NOT NULL,
    [OrderItemId]        INT             NULL,
    [Rating]             TINYINT         NOT NULL,
    [Title]              NVARCHAR (200)  NULL,
    [Body]               NVARCHAR (2000) NULL,
    [IsVerifiedPurchase] BIT             NOT NULL,
    [HelpfulCount]       INT             NOT NULL,
    [IsApproved]         BIT             NOT NULL,
    [ApprovedBy]         INT             NULL,
    [SentimentScore]     DECIMAL (4, 3)  NULL,
    [CreatedAt]          DATETIME2 (0)   NOT NULL,
    [UpdatedAt]          DATETIME2 (0)   NOT NULL,
    [CreatedBy]          INT             NULL,
    [UpdatedBy]          INT             NULL,
    [IsActive]           BIT             NOT NULL,
    [IsDeleted]          BIT             NOT NULL,
    CONSTRAINT [PK_Reviews] PRIMARY KEY CLUSTERED ([ReviewId] ASC),
    CONSTRAINT [UQ_Reviews_UserOrderItem] UNIQUE NONCLUSTERED ([UserId] ASC, [OrderItemId] ASC)
);


GO
PRINT N'Creating Index [dbo].[Reviews].[IX_Reviews_ProductId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Reviews_ProductId]
    ON [dbo].[Reviews]([ProductId] ASC, [IsApproved] ASC, [Rating] DESC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[Roles]...';


GO
CREATE TABLE [dbo].[Roles] (
    [RoleId]      TINYINT        NOT NULL,
    [RoleName]    NVARCHAR (50)  NOT NULL,
    [Description] NVARCHAR (200) NULL,
    [CreatedAt]   DATETIME2 (0)  NOT NULL,
    [UpdatedAt]   DATETIME2 (0)  NOT NULL,
    [CreatedBy]   INT            NULL,
    [UpdatedBy]   INT            NULL,
    [IsActive]    BIT            NOT NULL,
    [IsDeleted]   BIT            NOT NULL,
    CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED ([RoleId] ASC)
);


GO
PRINT N'Creating Table [dbo].[SearchLogs]...';


GO
CREATE TABLE [dbo].[SearchLogs] (
    [SearchId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [UserId]           INT            NULL,
    [SearchTerm]       NVARCHAR (500) NOT NULL,
    [ResultCount]      INT            NOT NULL,
    [ClickedProductId] INT            NULL,
    [SearchedAt]       DATETIME2 (0)  NOT NULL,
    CONSTRAINT [PK_SearchLogs] PRIMARY KEY CLUSTERED ([SearchId] ASC)
);


GO
PRINT N'Creating Index [dbo].[SearchLogs].[IX_SearchLogs_SearchedAt]...';


GO
CREATE NONCLUSTERED INDEX [IX_SearchLogs_SearchedAt]
    ON [dbo].[SearchLogs]([SearchedAt] DESC);


GO
PRINT N'Creating Index [dbo].[SearchLogs].[IX_SearchLogs_SearchTerm]...';


GO
CREATE NONCLUSTERED INDEX [IX_SearchLogs_SearchTerm]
    ON [dbo].[SearchLogs]([SearchTerm] ASC);


GO
PRINT N'Creating Table [dbo].[SellerAnalyticsDaily]...';


GO
CREATE TABLE [dbo].[SellerAnalyticsDaily] (
    [AnalyticsId]         INT             IDENTITY (1, 1) NOT NULL,
    [SellerId]            INT             NOT NULL,
    [AnalyticsDate]       DATE            NOT NULL,
    [TotalOrders]         INT             NOT NULL,
    [TotalRevenue]        DECIMAL (18, 2) NOT NULL,
    [TotalCommission]     DECIMAL (18, 2) NOT NULL,
    [TotalEarnings]       DECIMAL (18, 2) NOT NULL,
    [TotalProductViews]   INT             NOT NULL,
    [TotalUniqueVisitors] INT             NOT NULL,
    [CreatedAt]           DATETIME2 (0)   NOT NULL,
    [UpdatedAt]           DATETIME2 (0)   NOT NULL,
    [CreatedBy]           INT             NULL,
    [UpdatedBy]           INT             NULL,
    [IsActive]            BIT             NOT NULL,
    [IsDeleted]           BIT             NOT NULL,
    CONSTRAINT [PK_SellerAnalyticsDaily] PRIMARY KEY CLUSTERED ([AnalyticsId] ASC),
    CONSTRAINT [UQ_SellerAnalyticsDaily_SellerDate] UNIQUE NONCLUSTERED ([SellerId] ASC, [AnalyticsDate] ASC)
);


GO
PRINT N'Creating Table [dbo].[SellerBrandMappings]...';


GO
CREATE TABLE [dbo].[SellerBrandMappings] (
    [MappingId]  INT           IDENTITY (1, 1) NOT NULL,
    [SellerId]   INT           NOT NULL,
    [BrandId]    INT           NOT NULL,
    [ApprovedBy] INT           NULL,
    [ApprovedAt] DATETIME2 (0) NULL,
    [IsApproved] BIT           NOT NULL,
    [CreatedAt]  DATETIME2 (0) NOT NULL,
    [UpdatedAt]  DATETIME2 (0) NOT NULL,
    [CreatedBy]  INT           NULL,
    [UpdatedBy]  INT           NULL,
    [IsActive]   BIT           NOT NULL,
    [IsDeleted]  BIT           NOT NULL,
    CONSTRAINT [PK_SellerBrandMappings] PRIMARY KEY CLUSTERED ([MappingId] ASC),
    CONSTRAINT [UQ_SellerBrandMappings_SellerBrand] UNIQUE NONCLUSTERED ([SellerId] ASC, [BrandId] ASC)
);


GO
PRINT N'Creating Index [dbo].[SellerBrandMappings].[IX_SellerBrandMappings_BrandId]...';


GO
CREATE NONCLUSTERED INDEX [IX_SellerBrandMappings_BrandId]
    ON [dbo].[SellerBrandMappings]([BrandId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[SellerDocuments]...';


GO
CREATE TABLE [dbo].[SellerDocuments] (
    [DocumentId]   INT            IDENTITY (1, 1) NOT NULL,
    [SellerId]     INT            NOT NULL,
    [DocumentType] TINYINT        NOT NULL,
    [DocumentUrl]  NVARCHAR (500) NOT NULL,
    [IsVerified]   BIT            NOT NULL,
    [VerifiedBy]   INT            NULL,
    [CreatedAt]    DATETIME2 (0)  NOT NULL,
    [UpdatedAt]    DATETIME2 (0)  NOT NULL,
    [CreatedBy]    INT            NULL,
    [UpdatedBy]    INT            NULL,
    [IsActive]     BIT            NOT NULL,
    [IsDeleted]    BIT            NOT NULL,
    CONSTRAINT [PK_SellerDocuments] PRIMARY KEY CLUSTERED ([DocumentId] ASC)
);


GO
PRINT N'Creating Index [dbo].[SellerDocuments].[IX_SellerDocuments_SellerId]...';


GO
CREATE NONCLUSTERED INDEX [IX_SellerDocuments_SellerId]
    ON [dbo].[SellerDocuments]([SellerId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[Sellers]...';


GO
CREATE TABLE [dbo].[Sellers] (
    [SellerId]            INT            IDENTITY (1, 1) NOT NULL,
    [UserId]              INT            NOT NULL,
    [BusinessName]        NVARCHAR (300) NOT NULL,
    [GstNumber]           NVARCHAR (20)  NULL,
    [PanNumber]           NVARCHAR (20)  NULL,
    [BusinessAddressId]   INT            NULL,
    [BankAccountNumber]   NVARCHAR (50)  NULL,
    [BankIfscCode]        NVARCHAR (20)  NULL,
    [BankName]            NVARCHAR (100) NULL,
    [ApprovalStatus]      TINYINT        NOT NULL,
    [ApprovedBy]          INT            NULL,
    [ApprovedAt]          DATETIME2 (0)  NULL,
    [RejectionReason]     NVARCHAR (500) NULL,
    [CommissionRate]      DECIMAL (5, 2) NOT NULL,
    [OwnerName]           NVARCHAR (200) NULL,
    [DisplayName]         NVARCHAR (200) NULL,
    [StoreDescription]    NVARCHAR (MAX) NULL,
    [Description]         NVARCHAR (MAX) NULL,
    [BannerUrl]           NVARCHAR (500) NULL,
    [LogoUrl]             NVARCHAR (500) NULL,
    [SupportEmail]        NVARCHAR (256) NULL,
    [SupportPhone]        NVARCHAR (20)  NULL,
    [Address]             NVARCHAR (300) NULL,
    [City]                NVARCHAR (100) NULL,
    [State]               NVARCHAR (100) NULL,
    [Pincode]             NVARCHAR (10)  NULL,
    [IsIdVerified]        BIT            NOT NULL,
    [OnboardingCompleted] BIT            NOT NULL,
    [PickupAddressLine1]  NVARCHAR (300) NULL,
    [PickupAddressLine2]  NVARCHAR (300) NULL,
    [PickupCity]          NVARCHAR (100) NULL,
    [PickupState]         NVARCHAR (100) NULL,
    [PickupPincode]       NVARCHAR (10)  NULL,
    [PickupLandmark]      NVARCHAR (200) NULL,
    [SelectedCategories]  NVARCHAR (MAX) NULL,
    [CreatedAt]           DATETIME2 (0)  NOT NULL,
    [UpdatedAt]           DATETIME2 (0)  NOT NULL,
    [CreatedBy]           INT            NULL,
    [UpdatedBy]           INT            NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    CONSTRAINT [PK_Sellers] PRIMARY KEY CLUSTERED ([SellerId] ASC),
    CONSTRAINT [UQ_Sellers_UserId] UNIQUE NONCLUSTERED ([UserId] ASC)
);


GO
PRINT N'Creating Index [dbo].[Sellers].[IX_Sellers_ApprovalStatus]...';


GO
CREATE NONCLUSTERED INDEX [IX_Sellers_ApprovalStatus]
    ON [dbo].[Sellers]([ApprovalStatus] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[Stores]...';


GO
CREATE TABLE [dbo].[Stores] (
    [StoreId]   INT            IDENTITY (1, 1) NOT NULL,
    [StoreName] NVARCHAR (200) NOT NULL,
    [Address]   NVARCHAR (500) NOT NULL,
    [City]      NVARCHAR (100) NOT NULL,
    [State]     NVARCHAR (100) NOT NULL,
    [Pincode]   NVARCHAR (10)  NOT NULL,
    [Lat]       DECIMAL (9, 6) NULL,
    [Lng]       DECIMAL (9, 6) NULL,
    [Phone]     NVARCHAR (20)  NULL,
    [CreatedAt] DATETIME2 (0)  NOT NULL,
    [UpdatedAt] DATETIME2 (0)  NOT NULL,
    [IsActive]  BIT            NOT NULL,
    [IsDeleted] BIT            NOT NULL,
    CONSTRAINT [PK_Stores] PRIMARY KEY CLUSTERED ([StoreId] ASC)
);


GO
PRINT N'Creating Index [dbo].[Stores].[IX_Stores_City]...';


GO
CREATE NONCLUSTERED INDEX [IX_Stores_City]
    ON [dbo].[Stores]([City] ASC) WHERE [IsDeleted] = 0 AND [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[SubCategories]...';


GO
CREATE TABLE [dbo].[SubCategories] (
    [SubCategoryId]   INT            IDENTITY (1, 1) NOT NULL,
    [CategoryId]      INT            NOT NULL,
    [SubCategoryName] NVARCHAR (200) NOT NULL,
    [SlugUrl]         NVARCHAR (300) NOT NULL,
    [IconUrl]         NVARCHAR (500) NULL,
    [SortOrder]       INT            NOT NULL,
    [IsFeatured]      BIT            NOT NULL,
    [MetaTitle]       NVARCHAR (200) NULL,
    [MetaDescription] NVARCHAR (500) NULL,
    [CreatedAt]       DATETIME2 (0)  NOT NULL,
    [UpdatedAt]       DATETIME2 (0)  NOT NULL,
    [CreatedBy]       INT            NULL,
    [UpdatedBy]       INT            NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_SubCategories] PRIMARY KEY CLUSTERED ([SubCategoryId] ASC),
    CONSTRAINT [UQ_SubCategories_SlugUrl] UNIQUE NONCLUSTERED ([SlugUrl] ASC)
);


GO
PRINT N'Creating Index [dbo].[SubCategories].[IX_SubCategories_CategoryId]...';


GO
CREATE NONCLUSTERED INDEX [IX_SubCategories_CategoryId]
    ON [dbo].[SubCategories]([CategoryId] ASC, [SortOrder] ASC) WHERE [IsDeleted] = 0 AND [IsActive] = 1;


GO
PRINT N'Creating Table [dbo].[UserAddresses]...';


GO
CREATE TABLE [dbo].[UserAddresses] (
    [AddressId]    INT            IDENTITY (1, 1) NOT NULL,
    [UserId]       INT            NOT NULL,
    [Label]        NVARCHAR (50)  NULL,
    [AddressLine1] NVARCHAR (300) NOT NULL,
    [AddressLine2] NVARCHAR (300) NULL,
    [City]         NVARCHAR (100) NOT NULL,
    [State]        NVARCHAR (100) NOT NULL,
    [PinCode]      NVARCHAR (10)  NOT NULL,
    [Country]      NVARCHAR (100) NOT NULL,
    [Latitude]     DECIMAL (9, 6) NULL,
    [Longitude]    DECIMAL (9, 6) NULL,
    [IsDefault]    BIT            NOT NULL,
    [CreatedAt]    DATETIME2 (0)  NOT NULL,
    [UpdatedAt]    DATETIME2 (0)  NOT NULL,
    [CreatedBy]    INT            NULL,
    [UpdatedBy]    INT            NULL,
    [IsActive]     BIT            NOT NULL,
    [IsDeleted]    BIT            NOT NULL,
    CONSTRAINT [PK_UserAddresses] PRIMARY KEY CLUSTERED ([AddressId] ASC)
);


GO
PRINT N'Creating Index [dbo].[UserAddresses].[IX_UserAddresses_UserId]...';


GO
CREATE NONCLUSTERED INDEX [IX_UserAddresses_UserId]
    ON [dbo].[UserAddresses]([UserId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Table [dbo].[Users]...';


GO
CREATE TABLE [dbo].[Users] (
    [UserId]           INT            IDENTITY (1, 1) NOT NULL,
    [Email]            NVARCHAR (256) NOT NULL,
    [Mobile]           NVARCHAR (15)  NULL,
    [PasswordHash]     NVARCHAR (500) NOT NULL,
    [RoleId]           TINYINT        NOT NULL,
    [FirstName]        NVARCHAR (100) NULL,
    [LastName]         NVARCHAR (100) NULL,
    [ProfileImageUrl]  NVARCHAR (500) NULL,
    [IsEmailVerified]  BIT            NOT NULL,
    [IsMobileVerified] BIT            NOT NULL,
    [IsApproved]       BIT            NOT NULL,
    [LastLoginAt]      DATETIME2 (0)  NULL,
    [LoyaltyPoints]    INT            NOT NULL,
    [ReferralCode]     NVARCHAR (20)  NULL,
    [CreatedAt]        DATETIME2 (0)  NOT NULL,
    [UpdatedAt]        DATETIME2 (0)  NOT NULL,
    [CreatedBy]        INT            NULL,
    [UpdatedBy]        INT            NULL,
    [IsActive]         BIT            NOT NULL,
    [IsDeleted]        BIT            NOT NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([UserId] ASC),
    CONSTRAINT [UQ_Users_Email] UNIQUE NONCLUSTERED ([Email] ASC),
    CONSTRAINT [UQ_Users_Mobile] UNIQUE NONCLUSTERED ([Mobile] ASC),
    CONSTRAINT [UQ_Users_Referral] UNIQUE NONCLUSTERED ([ReferralCode] ASC)
);


GO
PRINT N'Creating Index [dbo].[Users].[IX_Users_RoleId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Users_RoleId]
    ON [dbo].[Users]([RoleId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Index [dbo].[Users].[IX_Users_IsDeleted]...';


GO
CREATE NONCLUSTERED INDEX [IX_Users_IsDeleted]
    ON [dbo].[Users]([IsDeleted] ASC, [IsActive] ASC);


GO
PRINT N'Creating Table [dbo].[Wallets]...';


GO
CREATE TABLE [dbo].[Wallets] (
    [WalletId]  INT             IDENTITY (1, 1) NOT NULL,
    [UserId]    INT             NOT NULL,
    [Balance]   DECIMAL (18, 2) NOT NULL,
    [CreatedAt] DATETIME2 (0)   NOT NULL,
    [UpdatedAt] DATETIME2 (0)   NOT NULL,
    CONSTRAINT [PK_Wallets] PRIMARY KEY CLUSTERED ([WalletId] ASC),
    CONSTRAINT [UQ_Wallets_UserId] UNIQUE NONCLUSTERED ([UserId] ASC)
);


GO
PRINT N'Creating Index [dbo].[Wallets].[IX_Wallets_UserId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Wallets_UserId]
    ON [dbo].[Wallets]([UserId] ASC);


GO
PRINT N'Creating Table [dbo].[WalletTransactions]...';


GO
CREATE TABLE [dbo].[WalletTransactions] (
    [TransactionId]   INT             IDENTITY (1, 1) NOT NULL,
    [WalletId]        INT             NOT NULL,
    [UserId]          INT             NOT NULL,
    [Amount]          DECIMAL (18, 2) NOT NULL,
    [TransactionType] TINYINT         NOT NULL,
    [ReferenceType]   NVARCHAR (50)   NULL,
    [ReferenceId]     INT             NULL,
    [Description]     NVARCHAR (300)  NOT NULL,
    [CreatedAt]       DATETIME2 (0)   NOT NULL,
    CONSTRAINT [PK_WalletTransactions] PRIMARY KEY CLUSTERED ([TransactionId] ASC)
);


GO
PRINT N'Creating Index [dbo].[WalletTransactions].[IX_WalletTransactions_UserId]...';


GO
CREATE NONCLUSTERED INDEX [IX_WalletTransactions_UserId]
    ON [dbo].[WalletTransactions]([UserId] ASC, [CreatedAt] DESC);


GO
PRINT N'Creating Table [dbo].[Wishlist]...';


GO
CREATE TABLE [dbo].[Wishlist] (
    [WishlistId] INT           IDENTITY (1, 1) NOT NULL,
    [UserId]     INT           NOT NULL,
    [ProductId]  INT           NOT NULL,
    [AddedAt]    DATETIME2 (0) NOT NULL,
    [CreatedAt]  DATETIME2 (0) NOT NULL,
    [UpdatedAt]  DATETIME2 (0) NOT NULL,
    [CreatedBy]  INT           NULL,
    [UpdatedBy]  INT           NULL,
    [IsActive]   BIT           NOT NULL,
    [IsDeleted]  BIT           NOT NULL,
    CONSTRAINT [PK_Wishlist] PRIMARY KEY CLUSTERED ([WishlistId] ASC),
    CONSTRAINT [UQ_Wishlist_UserProduct] UNIQUE NONCLUSTERED ([UserId] ASC, [ProductId] ASC)
);


GO
PRINT N'Creating Index [dbo].[Wishlist].[IX_Wishlist_UserId]...';


GO
CREATE NONCLUSTERED INDEX [IX_Wishlist_UserId]
    ON [dbo].[Wishlist]([UserId] ASC) WHERE [IsDeleted] = 0;


GO
PRINT N'Creating Default Constraint [dbo].[DF_AuditLogs_ChangedAt]...';


GO
ALTER TABLE [dbo].[AuditLogs]
    ADD CONSTRAINT [DF_AuditLogs_ChangedAt] DEFAULT GETUTCDATE() FOR [ChangedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_BankOffers_SortOrder]...';


GO
ALTER TABLE [dbo].[BankOffers]
    ADD CONSTRAINT [DF_BankOffers_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_BankOffers_CreatedAt]...';


GO
ALTER TABLE [dbo].[BankOffers]
    ADD CONSTRAINT [DF_BankOffers_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_BankOffers_UpdatedAt]...';


GO
ALTER TABLE [dbo].[BankOffers]
    ADD CONSTRAINT [DF_BankOffers_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_BankOffers_IsActive]...';


GO
ALTER TABLE [dbo].[BankOffers]
    ADD CONSTRAINT [DF_BankOffers_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_BankOffers_IsDeleted]...';


GO
ALTER TABLE [dbo].[BankOffers]
    ADD CONSTRAINT [DF_BankOffers_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Banners_LinkTarget]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [DF_Banners_LinkTarget] DEFAULT N'_self' FOR [LinkTarget];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Banners_BannerType]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [DF_Banners_BannerType] DEFAULT 1 FOR [BannerType];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Banners_SortOrder]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [DF_Banners_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Banners_CreatedAt]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [DF_Banners_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Banners_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [DF_Banners_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Banners_IsActive]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [DF_Banners_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Banners_IsDeleted]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [DF_Banners_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Brands_IsFeatured]...';


GO
ALTER TABLE [dbo].[Brands]
    ADD CONSTRAINT [DF_Brands_IsFeatured] DEFAULT 0 FOR [IsFeatured];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Brands_SortOrder]...';


GO
ALTER TABLE [dbo].[Brands]
    ADD CONSTRAINT [DF_Brands_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Brands_CreatedAt]...';


GO
ALTER TABLE [dbo].[Brands]
    ADD CONSTRAINT [DF_Brands_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Brands_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Brands]
    ADD CONSTRAINT [DF_Brands_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Brands_IsActive]...';


GO
ALTER TABLE [dbo].[Brands]
    ADD CONSTRAINT [DF_Brands_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Brands_IsDeleted]...';


GO
ALTER TABLE [dbo].[Brands]
    ADD CONSTRAINT [DF_Brands_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Cart_Quantity]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [DF_Cart_Quantity] DEFAULT 1 FOR [Quantity];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Cart_AddedAt]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [DF_Cart_AddedAt] DEFAULT GETUTCDATE() FOR [AddedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Cart_SavedForLater]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [DF_Cart_SavedForLater] DEFAULT 0 FOR [SavedForLater];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Cart_CreatedAt]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [DF_Cart_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Cart_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [DF_Cart_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Cart_IsActive]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [DF_Cart_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Cart_IsDeleted]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [DF_Cart_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Categories_MenuId]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [DF_Categories_MenuId] DEFAULT 1 FOR [MenuId];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Categories_SortOrder]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [DF_Categories_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Categories_IsFeatured]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [DF_Categories_IsFeatured] DEFAULT 0 FOR [IsFeatured];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Categories_CreatedAt]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [DF_Categories_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Categories_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [DF_Categories_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Categories_IsActive]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [DF_Categories_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Categories_IsDeleted]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [DF_Categories_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Coupons_CreatedAt]...';


GO
ALTER TABLE [dbo].[Coupons]
    ADD CONSTRAINT [DF_Coupons_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Coupons_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Coupons]
    ADD CONSTRAINT [DF_Coupons_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Coupons_IsActive]...';


GO
ALTER TABLE [dbo].[Coupons]
    ADD CONSTRAINT [DF_Coupons_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Coupons_IsDeleted]...';


GO
ALTER TABLE [dbo].[Coupons]
    ADD CONSTRAINT [DF_Coupons_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_FooterContent_SortOrder]...';


GO
ALTER TABLE [dbo].[FooterContent]
    ADD CONSTRAINT [DF_FooterContent_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_FooterContent_ColumnNumber]...';


GO
ALTER TABLE [dbo].[FooterContent]
    ADD CONSTRAINT [DF_FooterContent_ColumnNumber] DEFAULT 1 FOR [ColumnNumber];


GO
PRINT N'Creating Default Constraint [dbo].[DF_FooterContent_CreatedAt]...';


GO
ALTER TABLE [dbo].[FooterContent]
    ADD CONSTRAINT [DF_FooterContent_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_FooterContent_UpdatedAt]...';


GO
ALTER TABLE [dbo].[FooterContent]
    ADD CONSTRAINT [DF_FooterContent_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_FooterContent_IsActive]...';


GO
ALTER TABLE [dbo].[FooterContent]
    ADD CONSTRAINT [DF_FooterContent_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_FooterContent_IsDeleted]...';


GO
ALTER TABLE [dbo].[FooterContent]
    ADD CONSTRAINT [DF_FooterContent_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_GenderTypes_CreatedAt]...';


GO
ALTER TABLE [dbo].[GenderTypes]
    ADD CONSTRAINT [DF_GenderTypes_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_GenderTypes_UpdatedAt]...';


GO
ALTER TABLE [dbo].[GenderTypes]
    ADD CONSTRAINT [DF_GenderTypes_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_GenderTypes_IsActive]...';


GO
ALTER TABLE [dbo].[GenderTypes]
    ADD CONSTRAINT [DF_GenderTypes_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_GenderTypes_IsDeleted]...';


GO
ALTER TABLE [dbo].[GenderTypes]
    ADD CONSTRAINT [DF_GenderTypes_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_HomeSections_SortOrder]...';


GO
ALTER TABLE [dbo].[HomeSections]
    ADD CONSTRAINT [DF_HomeSections_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_HomeSections_ItemsToShow]...';


GO
ALTER TABLE [dbo].[HomeSections]
    ADD CONSTRAINT [DF_HomeSections_ItemsToShow] DEFAULT 8 FOR [ItemsToShow];


GO
PRINT N'Creating Default Constraint [dbo].[DF_HomeSections_CreatedAt]...';


GO
ALTER TABLE [dbo].[HomeSections]
    ADD CONSTRAINT [DF_HomeSections_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_HomeSections_UpdatedAt]...';


GO
ALTER TABLE [dbo].[HomeSections]
    ADD CONSTRAINT [DF_HomeSections_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_HomeSections_IsActive]...';


GO
ALTER TABLE [dbo].[HomeSections]
    ADD CONSTRAINT [DF_HomeSections_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_HomeSections_IsDeleted]...';


GO
ALTER TABLE [dbo].[HomeSections]
    ADD CONSTRAINT [DF_HomeSections_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Menus_SortOrder]...';


GO
ALTER TABLE [dbo].[Menus]
    ADD CONSTRAINT [DF_Menus_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Menus_IsActive]...';


GO
ALTER TABLE [dbo].[Menus]
    ADD CONSTRAINT [DF_Menus_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Menus_IsDeleted]...';


GO
ALTER TABLE [dbo].[Menus]
    ADD CONSTRAINT [DF_Menus_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Menus_CreatedAt]...';


GO
ALTER TABLE [dbo].[Menus]
    ADD CONSTRAINT [DF_Menus_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Notifications_IsRead]...';


GO
ALTER TABLE [dbo].[Notifications]
    ADD CONSTRAINT [DF_Notifications_IsRead] DEFAULT 0 FOR [IsRead];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Notifications_Channel]...';


GO
ALTER TABLE [dbo].[Notifications]
    ADD CONSTRAINT [DF_Notifications_Channel] DEFAULT 1 FOR [Channel];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Notifications_CreatedAt]...';


GO
ALTER TABLE [dbo].[Notifications]
    ADD CONSTRAINT [DF_Notifications_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Notifications_IsDeleted]...';


GO
ALTER TABLE [dbo].[Notifications]
    ADD CONSTRAINT [DF_Notifications_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Offers_MinOrderValue]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [DF_Offers_MinOrderValue] DEFAULT 0 FOR [MinOrderValue];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Offers_UsageLimitPerUser]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [DF_Offers_UsageLimitPerUser] DEFAULT 1 FOR [UsageLimitPerUser];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Offers_CurrentUsageCount]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [DF_Offers_CurrentUsageCount] DEFAULT 0 FOR [CurrentUsageCount];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Offers_CreatedAt]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [DF_Offers_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Offers_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [DF_Offers_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Offers_IsActive]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [DF_Offers_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Offers_IsDeleted]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [DF_Offers_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OrderItems_DiscountAmount]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [DF_OrderItems_DiscountAmount] DEFAULT 0 FOR [DiscountAmount];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OrderItems_TaxAmount]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [DF_OrderItems_TaxAmount] DEFAULT 0 FOR [TaxAmount];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OrderItems_IsReturned]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [DF_OrderItems_IsReturned] DEFAULT 0 FOR [IsReturned];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OrderItems_CreatedAt]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [DF_OrderItems_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OrderItems_UpdatedAt]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [DF_OrderItems_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OrderItems_IsActive]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [DF_OrderItems_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OrderItems_IsDeleted]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [DF_OrderItems_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_OrderStatus]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_OrderStatus] DEFAULT 1 FOR [OrderStatus];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_DiscountAmount]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_DiscountAmount] DEFAULT 0 FOR [DiscountAmount];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_CouponDiscount]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_CouponDiscount] DEFAULT 0 FOR [CouponDiscount];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_TaxAmount]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_TaxAmount] DEFAULT 0 FOR [TaxAmount];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_ShippingCharge]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_ShippingCharge] DEFAULT 0 FOR [ShippingCharge];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_PaymentStatus]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_PaymentStatus] DEFAULT 1 FOR [PaymentStatus];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_CreatedAt]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_IsActive]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Orders_IsDeleted]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OtpVerifications_IsUsed]...';


GO
ALTER TABLE [dbo].[OtpVerifications]
    ADD CONSTRAINT [DF_OtpVerifications_IsUsed] DEFAULT 0 FOR [IsUsed];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OtpVerifications_AttemptCount]...';


GO
ALTER TABLE [dbo].[OtpVerifications]
    ADD CONSTRAINT [DF_OtpVerifications_AttemptCount] DEFAULT 0 FOR [AttemptCount];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OtpVerifications_CreatedAt]...';


GO
ALTER TABLE [dbo].[OtpVerifications]
    ADD CONSTRAINT [DF_OtpVerifications_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_OtpVerifications_IsDeleted]...';


GO
ALTER TABLE [dbo].[OtpVerifications]
    ADD CONSTRAINT [DF_OtpVerifications_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Pincodes_EstimatedDays]...';


GO
ALTER TABLE [dbo].[Pincodes]
    ADD CONSTRAINT [DF_Pincodes_EstimatedDays] DEFAULT 5 FOR [EstimatedDays];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Pincodes_CODAvailable]...';


GO
ALTER TABLE [dbo].[Pincodes]
    ADD CONSTRAINT [DF_Pincodes_CODAvailable] DEFAULT 1 FOR [CODAvailable];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Pincodes_IsActive]...';


GO
ALTER TABLE [dbo].[Pincodes]
    ADD CONSTRAINT [DF_Pincodes_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Pincodes_CreatedAt]...';


GO
ALTER TABLE [dbo].[Pincodes]
    ADD CONSTRAINT [DF_Pincodes_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Pincodes_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Pincodes]
    ADD CONSTRAINT [DF_Pincodes_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_PriceHistory_ChangedAt]...';


GO
ALTER TABLE [dbo].[PriceHistory]
    ADD CONSTRAINT [DF_PriceHistory_ChangedAt] DEFAULT GETUTCDATE() FOR [ChangedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductImages_SortOrder]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [DF_ProductImages_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductImages_IsPrimary]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [DF_ProductImages_IsPrimary] DEFAULT 0 FOR [IsPrimary];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductImages_CreatedAt]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [DF_ProductImages_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductImages_UpdatedAt]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [DF_ProductImages_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductImages_IsActive]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [DF_ProductImages_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductImages_IsDeleted]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [DF_ProductImages_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_GstRate]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_GstRate] DEFAULT 0 FOR [GstRate];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_IsReturnable]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_IsReturnable] DEFAULT 1 FOR [IsReturnable];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_ReturnWindowDays]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_ReturnWindowDays] DEFAULT 7 FOR [ReturnWindowDays];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_IsCODAvailable]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_IsCODAvailable] DEFAULT 1 FOR [IsCODAvailable];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_IsFeatured]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_IsFeatured] DEFAULT 0 FOR [IsFeatured];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_SortOrder]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_ApprovalStatus]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_ApprovalStatus] DEFAULT 1 FOR [ApprovalStatus];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_CreatedAt]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_IsActive]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Products_IsDeleted]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductSpecifications_SortOrder]...';


GO
ALTER TABLE [dbo].[ProductSpecifications]
    ADD CONSTRAINT [DF_ProductSpecifications_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductSpecifications_CreatedAt]...';


GO
ALTER TABLE [dbo].[ProductSpecifications]
    ADD CONSTRAINT [DF_ProductSpecifications_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductSpecifications_IsDeleted]...';


GO
ALTER TABLE [dbo].[ProductSpecifications]
    ADD CONSTRAINT [DF_ProductSpecifications_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_PSC_CreatedAt]...';


GO
ALTER TABLE [dbo].[ProductSubCategories]
    ADD CONSTRAINT [DF_PSC_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductVariants_AdditionalPrice]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [DF_ProductVariants_AdditionalPrice] DEFAULT 0 FOR [AdditionalPrice];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductVariants_StockQuantity]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [DF_ProductVariants_StockQuantity] DEFAULT 0 FOR [StockQuantity];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductVariants_LowStockThreshold]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [DF_ProductVariants_LowStockThreshold] DEFAULT 5 FOR [LowStockThreshold];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductVariants_CreatedAt]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [DF_ProductVariants_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductVariants_UpdatedAt]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [DF_ProductVariants_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductVariants_IsActive]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [DF_ProductVariants_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductVariants_IsDeleted]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [DF_ProductVariants_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ProductViewLogs_ViewedAt]...';


GO
ALTER TABLE [dbo].[ProductViewLogs]
    ADD CONSTRAINT [DF_ProductViewLogs_ViewedAt] DEFAULT GETUTCDATE() FOR [ViewedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_RecentlyViewed_ViewedAt]...';


GO
ALTER TABLE [dbo].[RecentlyViewed]
    ADD CONSTRAINT [DF_RecentlyViewed_ViewedAt] DEFAULT GETUTCDATE() FOR [ViewedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_RecentlyViewed_CreatedAt]...';


GO
ALTER TABLE [dbo].[RecentlyViewed]
    ADD CONSTRAINT [DF_RecentlyViewed_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_RecentlyViewed_UpdatedAt]...';


GO
ALTER TABLE [dbo].[RecentlyViewed]
    ADD CONSTRAINT [DF_RecentlyViewed_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_RecentlyViewed_IsDeleted]...';


GO
ALTER TABLE [dbo].[RecentlyViewed]
    ADD CONSTRAINT [DF_RecentlyViewed_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_RefreshTokens_IsRevoked]...';


GO
ALTER TABLE [dbo].[RefreshTokens]
    ADD CONSTRAINT [DF_RefreshTokens_IsRevoked] DEFAULT 0 FOR [IsRevoked];


GO
PRINT N'Creating Default Constraint [dbo].[DF_RefreshTokens_CreatedAt]...';


GO
ALTER TABLE [dbo].[RefreshTokens]
    ADD CONSTRAINT [DF_RefreshTokens_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ReviewImages_CreatedAt]...';


GO
ALTER TABLE [dbo].[ReviewImages]
    ADD CONSTRAINT [DF_ReviewImages_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_ReviewImages_IsDeleted]...';


GO
ALTER TABLE [dbo].[ReviewImages]
    ADD CONSTRAINT [DF_ReviewImages_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Reviews_IsVerifiedPurchase]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [DF_Reviews_IsVerifiedPurchase] DEFAULT 0 FOR [IsVerifiedPurchase];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Reviews_HelpfulCount]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [DF_Reviews_HelpfulCount] DEFAULT 0 FOR [HelpfulCount];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Reviews_IsApproved]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [DF_Reviews_IsApproved] DEFAULT 0 FOR [IsApproved];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Reviews_CreatedAt]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [DF_Reviews_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Reviews_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [DF_Reviews_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Reviews_IsActive]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [DF_Reviews_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Reviews_IsDeleted]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [DF_Reviews_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Roles_CreatedAt]...';


GO
ALTER TABLE [dbo].[Roles]
    ADD CONSTRAINT [DF_Roles_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Roles_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Roles]
    ADD CONSTRAINT [DF_Roles_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Roles_IsActive]...';


GO
ALTER TABLE [dbo].[Roles]
    ADD CONSTRAINT [DF_Roles_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Roles_IsDeleted]...';


GO
ALTER TABLE [dbo].[Roles]
    ADD CONSTRAINT [DF_Roles_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SearchLogs_ResultCount]...';


GO
ALTER TABLE [dbo].[SearchLogs]
    ADD CONSTRAINT [DF_SearchLogs_ResultCount] DEFAULT 0 FOR [ResultCount];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SearchLogs_SearchedAt]...';


GO
ALTER TABLE [dbo].[SearchLogs]
    ADD CONSTRAINT [DF_SearchLogs_SearchedAt] DEFAULT GETUTCDATE() FOR [SearchedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_TotalOrders]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_TotalOrders] DEFAULT 0 FOR [TotalOrders];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_TotalRevenue]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_TotalRevenue] DEFAULT 0 FOR [TotalRevenue];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_TotalCommission]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_TotalCommission] DEFAULT 0 FOR [TotalCommission];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_TotalEarnings]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_TotalEarnings] DEFAULT 0 FOR [TotalEarnings];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_TotalProductViews]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_TotalProductViews] DEFAULT 0 FOR [TotalProductViews];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_TotalUniqueVisitors]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_TotalUniqueVisitors] DEFAULT 0 FOR [TotalUniqueVisitors];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_CreatedAt]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_UpdatedAt]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_IsActive]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerAnalyticsDaily_IsDeleted]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [DF_SellerAnalyticsDaily_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerBrandMappings_IsApproved]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [DF_SellerBrandMappings_IsApproved] DEFAULT 0 FOR [IsApproved];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerBrandMappings_CreatedAt]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [DF_SellerBrandMappings_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerBrandMappings_UpdatedAt]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [DF_SellerBrandMappings_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerBrandMappings_IsActive]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [DF_SellerBrandMappings_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerBrandMappings_IsDeleted]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [DF_SellerBrandMappings_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerDocuments_IsVerified]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [DF_SellerDocuments_IsVerified] DEFAULT 0 FOR [IsVerified];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerDocuments_CreatedAt]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [DF_SellerDocuments_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerDocuments_UpdatedAt]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [DF_SellerDocuments_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerDocuments_IsActive]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [DF_SellerDocuments_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SellerDocuments_IsDeleted]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [DF_SellerDocuments_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Sellers_ApprovalStatus]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [DF_Sellers_ApprovalStatus] DEFAULT 1 FOR [ApprovalStatus];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Sellers_CommissionRate]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [DF_Sellers_CommissionRate] DEFAULT 10.00 FOR [CommissionRate];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Sellers_IsIdVerified]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [DF_Sellers_IsIdVerified] DEFAULT 0 FOR [IsIdVerified];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Sellers_OnboardingCompleted]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [DF_Sellers_OnboardingCompleted] DEFAULT 0 FOR [OnboardingCompleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Sellers_CreatedAt]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [DF_Sellers_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Sellers_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [DF_Sellers_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Sellers_IsActive]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [DF_Sellers_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Sellers_IsDeleted]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [DF_Sellers_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Stores_CreatedAt]...';


GO
ALTER TABLE [dbo].[Stores]
    ADD CONSTRAINT [DF_Stores_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Stores_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Stores]
    ADD CONSTRAINT [DF_Stores_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Stores_IsActive]...';


GO
ALTER TABLE [dbo].[Stores]
    ADD CONSTRAINT [DF_Stores_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Stores_IsDeleted]...';


GO
ALTER TABLE [dbo].[Stores]
    ADD CONSTRAINT [DF_Stores_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SubCategories_SortOrder]...';


GO
ALTER TABLE [dbo].[SubCategories]
    ADD CONSTRAINT [DF_SubCategories_SortOrder] DEFAULT 0 FOR [SortOrder];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SubCategories_IsFeatured]...';


GO
ALTER TABLE [dbo].[SubCategories]
    ADD CONSTRAINT [DF_SubCategories_IsFeatured] DEFAULT 0 FOR [IsFeatured];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SubCategories_CreatedAt]...';


GO
ALTER TABLE [dbo].[SubCategories]
    ADD CONSTRAINT [DF_SubCategories_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SubCategories_UpdatedAt]...';


GO
ALTER TABLE [dbo].[SubCategories]
    ADD CONSTRAINT [DF_SubCategories_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SubCategories_IsActive]...';


GO
ALTER TABLE [dbo].[SubCategories]
    ADD CONSTRAINT [DF_SubCategories_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_SubCategories_IsDeleted]...';


GO
ALTER TABLE [dbo].[SubCategories]
    ADD CONSTRAINT [DF_SubCategories_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_UserAddresses_Country]...';


GO
ALTER TABLE [dbo].[UserAddresses]
    ADD CONSTRAINT [DF_UserAddresses_Country] DEFAULT N'India' FOR [Country];


GO
PRINT N'Creating Default Constraint [dbo].[DF_UserAddresses_IsDefault]...';


GO
ALTER TABLE [dbo].[UserAddresses]
    ADD CONSTRAINT [DF_UserAddresses_IsDefault] DEFAULT 0 FOR [IsDefault];


GO
PRINT N'Creating Default Constraint [dbo].[DF_UserAddresses_CreatedAt]...';


GO
ALTER TABLE [dbo].[UserAddresses]
    ADD CONSTRAINT [DF_UserAddresses_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_UserAddresses_UpdatedAt]...';


GO
ALTER TABLE [dbo].[UserAddresses]
    ADD CONSTRAINT [DF_UserAddresses_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_UserAddresses_IsActive]...';


GO
ALTER TABLE [dbo].[UserAddresses]
    ADD CONSTRAINT [DF_UserAddresses_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_UserAddresses_IsDeleted]...';


GO
ALTER TABLE [dbo].[UserAddresses]
    ADD CONSTRAINT [DF_UserAddresses_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Users_IsEmailVerified]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [DF_Users_IsEmailVerified] DEFAULT 0 FOR [IsEmailVerified];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Users_IsMobileVerified]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [DF_Users_IsMobileVerified] DEFAULT 0 FOR [IsMobileVerified];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Users_IsApproved]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [DF_Users_IsApproved] DEFAULT 0 FOR [IsApproved];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Users_LoyaltyPoints]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [DF_Users_LoyaltyPoints] DEFAULT 0 FOR [LoyaltyPoints];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Users_CreatedAt]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [DF_Users_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Users_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [DF_Users_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Users_IsActive]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [DF_Users_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Users_IsDeleted]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [DF_Users_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Wallets_Balance]...';


GO
ALTER TABLE [dbo].[Wallets]
    ADD CONSTRAINT [DF_Wallets_Balance] DEFAULT 0.00 FOR [Balance];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Wallets_CreatedAt]...';


GO
ALTER TABLE [dbo].[Wallets]
    ADD CONSTRAINT [DF_Wallets_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Wallets_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Wallets]
    ADD CONSTRAINT [DF_Wallets_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_WalletTransactions_CreatedAt]...';


GO
ALTER TABLE [dbo].[WalletTransactions]
    ADD CONSTRAINT [DF_WalletTransactions_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Wishlist_AddedAt]...';


GO
ALTER TABLE [dbo].[Wishlist]
    ADD CONSTRAINT [DF_Wishlist_AddedAt] DEFAULT GETUTCDATE() FOR [AddedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Wishlist_CreatedAt]...';


GO
ALTER TABLE [dbo].[Wishlist]
    ADD CONSTRAINT [DF_Wishlist_CreatedAt] DEFAULT GETUTCDATE() FOR [CreatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Wishlist_UpdatedAt]...';


GO
ALTER TABLE [dbo].[Wishlist]
    ADD CONSTRAINT [DF_Wishlist_UpdatedAt] DEFAULT GETUTCDATE() FOR [UpdatedAt];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Wishlist_IsActive]...';


GO
ALTER TABLE [dbo].[Wishlist]
    ADD CONSTRAINT [DF_Wishlist_IsActive] DEFAULT 1 FOR [IsActive];


GO
PRINT N'Creating Default Constraint [dbo].[DF_Wishlist_IsDeleted]...';


GO
ALTER TABLE [dbo].[Wishlist]
    ADD CONSTRAINT [DF_Wishlist_IsDeleted] DEFAULT 0 FOR [IsDeleted];


GO
PRINT N'Creating Foreign Key [dbo].[FK_AuditLogs_ChangedBy]...';


GO
ALTER TABLE [dbo].[AuditLogs]
    ADD CONSTRAINT [FK_AuditLogs_ChangedBy] FOREIGN KEY ([ChangedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Banners_CreatedBy]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [FK_Banners_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Banners_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [FK_Banners_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Brands_CreatedBy]...';


GO
ALTER TABLE [dbo].[Brands]
    ADD CONSTRAINT [FK_Brands_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Brands_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Brands]
    ADD CONSTRAINT [FK_Brands_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Cart_UserId]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [FK_Cart_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Cart_ProductId]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [FK_Cart_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Cart_VariantId]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [FK_Cart_VariantId] FOREIGN KEY ([VariantId]) REFERENCES [dbo].[ProductVariants] ([VariantId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Cart_CreatedBy]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [FK_Cart_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Cart_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Cart]
    ADD CONSTRAINT [FK_Cart_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Categories_MenuId]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [FK_Categories_MenuId] FOREIGN KEY ([MenuId]) REFERENCES [dbo].[Menus] ([MenuId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Categories_CreatedBy]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [FK_Categories_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Categories_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Categories]
    ADD CONSTRAINT [FK_Categories_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Coupons_OfferId]...';


GO
ALTER TABLE [dbo].[Coupons]
    ADD CONSTRAINT [FK_Coupons_OfferId] FOREIGN KEY ([OfferId]) REFERENCES [dbo].[Offers] ([OfferId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Coupons_CreatedBy]...';


GO
ALTER TABLE [dbo].[Coupons]
    ADD CONSTRAINT [FK_Coupons_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Coupons_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Coupons]
    ADD CONSTRAINT [FK_Coupons_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_FooterContent_CreatedBy]...';


GO
ALTER TABLE [dbo].[FooterContent]
    ADD CONSTRAINT [FK_FooterContent_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_FooterContent_UpdatedBy]...';


GO
ALTER TABLE [dbo].[FooterContent]
    ADD CONSTRAINT [FK_FooterContent_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_GenderTypes_CreatedBy]...';


GO
ALTER TABLE [dbo].[GenderTypes]
    ADD CONSTRAINT [FK_GenderTypes_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_GenderTypes_UpdatedBy]...';


GO
ALTER TABLE [dbo].[GenderTypes]
    ADD CONSTRAINT [FK_GenderTypes_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_HomeSections_CreatedBy]...';


GO
ALTER TABLE [dbo].[HomeSections]
    ADD CONSTRAINT [FK_HomeSections_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_HomeSections_UpdatedBy]...';


GO
ALTER TABLE [dbo].[HomeSections]
    ADD CONSTRAINT [FK_HomeSections_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Notifications_UserId]...';


GO
ALTER TABLE [dbo].[Notifications]
    ADD CONSTRAINT [FK_Notifications_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Offers_CreatedBy]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [FK_Offers_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Offers_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [FK_Offers_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_OrderItems_OrderId]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [FK_OrderItems_OrderId] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([OrderId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_OrderItems_ProductId]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [FK_OrderItems_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_OrderItems_VariantId]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [FK_OrderItems_VariantId] FOREIGN KEY ([VariantId]) REFERENCES [dbo].[ProductVariants] ([VariantId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_OrderItems_SellerId]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [FK_OrderItems_SellerId] FOREIGN KEY ([SellerId]) REFERENCES [dbo].[Sellers] ([SellerId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_OrderItems_BrandId]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [FK_OrderItems_BrandId] FOREIGN KEY ([BrandId]) REFERENCES [dbo].[Brands] ([BrandId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_OrderItems_CreatedBy]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [FK_OrderItems_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_OrderItems_UpdatedBy]...';


GO
ALTER TABLE [dbo].[OrderItems]
    ADD CONSTRAINT [FK_OrderItems_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Orders_UserId]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [FK_Orders_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Orders_CouponId]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [FK_Orders_CouponId] FOREIGN KEY ([CouponId]) REFERENCES [dbo].[Coupons] ([CouponId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Orders_ShippingAddressId]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [FK_Orders_ShippingAddressId] FOREIGN KEY ([ShippingAddressId]) REFERENCES [dbo].[UserAddresses] ([AddressId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Orders_CreatedBy]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [FK_Orders_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Orders_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [FK_Orders_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_OtpVerifications_UserId]...';


GO
ALTER TABLE [dbo].[OtpVerifications]
    ADD CONSTRAINT [FK_OtpVerifications_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_PriceHistory_ProductId]...';


GO
ALTER TABLE [dbo].[PriceHistory]
    ADD CONSTRAINT [FK_PriceHistory_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_PriceHistory_ChangedBy]...';


GO
ALTER TABLE [dbo].[PriceHistory]
    ADD CONSTRAINT [FK_PriceHistory_ChangedBy] FOREIGN KEY ([ChangedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductImages_ProductId]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [FK_ProductImages_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductImages_VariantId]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [FK_ProductImages_VariantId] FOREIGN KEY ([VariantId]) REFERENCES [dbo].[ProductVariants] ([VariantId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductImages_CreatedBy]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [FK_ProductImages_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductImages_UpdatedBy]...';


GO
ALTER TABLE [dbo].[ProductImages]
    ADD CONSTRAINT [FK_ProductImages_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Products_SellerId]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [FK_Products_SellerId] FOREIGN KEY ([SellerId]) REFERENCES [dbo].[Sellers] ([SellerId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Products_BrandId]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [FK_Products_BrandId] FOREIGN KEY ([BrandId]) REFERENCES [dbo].[Brands] ([BrandId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Products_CategoryId]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [FK_Products_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[Categories] ([CategoryId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Products_SubCategoryId]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [FK_Products_SubCategoryId] FOREIGN KEY ([SubCategoryId]) REFERENCES [dbo].[SubCategories] ([SubCategoryId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Products_GenderTypeId]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [FK_Products_GenderTypeId] FOREIGN KEY ([GenderTypeId]) REFERENCES [dbo].[GenderTypes] ([GenderTypeId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Products_ApprovedBy]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [FK_Products_ApprovedBy] FOREIGN KEY ([ApprovedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Products_CreatedBy]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [FK_Products_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Products_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [FK_Products_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductSpecifications_ProductId]...';


GO
ALTER TABLE [dbo].[ProductSpecifications]
    ADD CONSTRAINT [FK_ProductSpecifications_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_PSC_Product]...';


GO
ALTER TABLE [dbo].[ProductSubCategories]
    ADD CONSTRAINT [FK_PSC_Product] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_PSC_SubCategory]...';


GO
ALTER TABLE [dbo].[ProductSubCategories]
    ADD CONSTRAINT [FK_PSC_SubCategory] FOREIGN KEY ([SubCategoryId]) REFERENCES [dbo].[SubCategories] ([SubCategoryId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductVariants_ProductId]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [FK_ProductVariants_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductVariants_CreatedBy]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [FK_ProductVariants_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductVariants_UpdatedBy]...';


GO
ALTER TABLE [dbo].[ProductVariants]
    ADD CONSTRAINT [FK_ProductVariants_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductViewLogs_ProductId]...';


GO
ALTER TABLE [dbo].[ProductViewLogs]
    ADD CONSTRAINT [FK_ProductViewLogs_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ProductViewLogs_UserId]...';


GO
ALTER TABLE [dbo].[ProductViewLogs]
    ADD CONSTRAINT [FK_ProductViewLogs_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_RecentlyViewed_UserId]...';


GO
ALTER TABLE [dbo].[RecentlyViewed]
    ADD CONSTRAINT [FK_RecentlyViewed_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_RecentlyViewed_ProductId]...';


GO
ALTER TABLE [dbo].[RecentlyViewed]
    ADD CONSTRAINT [FK_RecentlyViewed_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_RefreshTokens_UserId]...';


GO
ALTER TABLE [dbo].[RefreshTokens]
    ADD CONSTRAINT [FK_RefreshTokens_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_ReviewImages_ReviewId]...';


GO
ALTER TABLE [dbo].[ReviewImages]
    ADD CONSTRAINT [FK_ReviewImages_ReviewId] FOREIGN KEY ([ReviewId]) REFERENCES [dbo].[Reviews] ([ReviewId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Reviews_ProductId]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [FK_Reviews_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Reviews_UserId]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [FK_Reviews_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Reviews_OrderItemId]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [FK_Reviews_OrderItemId] FOREIGN KEY ([OrderItemId]) REFERENCES [dbo].[OrderItems] ([OrderItemId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Reviews_ApprovedBy]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [FK_Reviews_ApprovedBy] FOREIGN KEY ([ApprovedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Reviews_CreatedBy]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [FK_Reviews_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Reviews_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [FK_Reviews_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Roles_CreatedBy]...';


GO
ALTER TABLE [dbo].[Roles]
    ADD CONSTRAINT [FK_Roles_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Roles_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Roles]
    ADD CONSTRAINT [FK_Roles_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SearchLogs_UserId]...';


GO
ALTER TABLE [dbo].[SearchLogs]
    ADD CONSTRAINT [FK_SearchLogs_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SearchLogs_ClickedProductId]...';


GO
ALTER TABLE [dbo].[SearchLogs]
    ADD CONSTRAINT [FK_SearchLogs_ClickedProductId] FOREIGN KEY ([ClickedProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerAnalyticsDaily_SellerId]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [FK_SellerAnalyticsDaily_SellerId] FOREIGN KEY ([SellerId]) REFERENCES [dbo].[Sellers] ([SellerId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerAnalyticsDaily_CreatedBy]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [FK_SellerAnalyticsDaily_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerAnalyticsDaily_UpdatedBy]...';


GO
ALTER TABLE [dbo].[SellerAnalyticsDaily]
    ADD CONSTRAINT [FK_SellerAnalyticsDaily_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerBrandMappings_SellerId]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [FK_SellerBrandMappings_SellerId] FOREIGN KEY ([SellerId]) REFERENCES [dbo].[Sellers] ([SellerId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerBrandMappings_BrandId]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [FK_SellerBrandMappings_BrandId] FOREIGN KEY ([BrandId]) REFERENCES [dbo].[Brands] ([BrandId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerBrandMappings_ApprovedBy]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [FK_SellerBrandMappings_ApprovedBy] FOREIGN KEY ([ApprovedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerBrandMappings_CreatedBy]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [FK_SellerBrandMappings_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerBrandMappings_UpdatedBy]...';


GO
ALTER TABLE [dbo].[SellerBrandMappings]
    ADD CONSTRAINT [FK_SellerBrandMappings_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerDocuments_SellerId]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [FK_SellerDocuments_SellerId] FOREIGN KEY ([SellerId]) REFERENCES [dbo].[Sellers] ([SellerId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerDocuments_VerifiedBy]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [FK_SellerDocuments_VerifiedBy] FOREIGN KEY ([VerifiedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerDocuments_CreatedBy]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [FK_SellerDocuments_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SellerDocuments_UpdatedBy]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [FK_SellerDocuments_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Sellers_UserId]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [FK_Sellers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Sellers_BusinessAddressId]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [FK_Sellers_BusinessAddressId] FOREIGN KEY ([BusinessAddressId]) REFERENCES [dbo].[UserAddresses] ([AddressId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Sellers_ApprovedBy]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [FK_Sellers_ApprovedBy] FOREIGN KEY ([ApprovedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Sellers_CreatedBy]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [FK_Sellers_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Sellers_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [FK_Sellers_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SubCategories_CategoryId]...';


GO
ALTER TABLE [dbo].[SubCategories]
    ADD CONSTRAINT [FK_SubCategories_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[Categories] ([CategoryId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SubCategories_CreatedBy]...';


GO
ALTER TABLE [dbo].[SubCategories]
    ADD CONSTRAINT [FK_SubCategories_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_SubCategories_UpdatedBy]...';


GO
ALTER TABLE [dbo].[SubCategories]
    ADD CONSTRAINT [FK_SubCategories_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_UserAddresses_UserId]...';


GO
ALTER TABLE [dbo].[UserAddresses]
    ADD CONSTRAINT [FK_UserAddresses_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_UserAddresses_CreatedBy]...';


GO
ALTER TABLE [dbo].[UserAddresses]
    ADD CONSTRAINT [FK_UserAddresses_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_UserAddresses_UpdatedBy]...';


GO
ALTER TABLE [dbo].[UserAddresses]
    ADD CONSTRAINT [FK_UserAddresses_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Users_RoleId]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [FK_Users_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles] ([RoleId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Users_CreatedBy]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [FK_Users_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Users_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Users]
    ADD CONSTRAINT [FK_Users_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Wallets_UserId]...';


GO
ALTER TABLE [dbo].[Wallets]
    ADD CONSTRAINT [FK_Wallets_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_WalletTransactions_WalletId]...';


GO
ALTER TABLE [dbo].[WalletTransactions]
    ADD CONSTRAINT [FK_WalletTransactions_WalletId] FOREIGN KEY ([WalletId]) REFERENCES [dbo].[Wallets] ([WalletId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_WalletTransactions_UserId]...';


GO
ALTER TABLE [dbo].[WalletTransactions]
    ADD CONSTRAINT [FK_WalletTransactions_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Wishlist_UserId]...';


GO
ALTER TABLE [dbo].[Wishlist]
    ADD CONSTRAINT [FK_Wishlist_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Wishlist_ProductId]...';


GO
ALTER TABLE [dbo].[Wishlist]
    ADD CONSTRAINT [FK_Wishlist_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Wishlist_CreatedBy]...';


GO
ALTER TABLE [dbo].[Wishlist]
    ADD CONSTRAINT [FK_Wishlist_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Foreign Key [dbo].[FK_Wishlist_UpdatedBy]...';


GO
ALTER TABLE [dbo].[Wishlist]
    ADD CONSTRAINT [FK_Wishlist_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId]);


GO
PRINT N'Creating Check Constraint [dbo].[CK_AuditLogs_Action]...';


GO
ALTER TABLE [dbo].[AuditLogs]
    ADD CONSTRAINT [CK_AuditLogs_Action] CHECK ([Action] IN (N'INSERT', N'UPDATE', N'DELETE'));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Banners_BannerType]...';


GO
ALTER TABLE [dbo].[Banners]
    ADD CONSTRAINT [CK_Banners_BannerType] CHECK ([BannerType] BETWEEN 1 AND 7);


GO
PRINT N'Creating Check Constraint [dbo].[CK_HomeSections_SectionType]...';


GO
ALTER TABLE [dbo].[HomeSections]
    ADD CONSTRAINT [CK_HomeSections_SectionType] CHECK ([SectionType] IN (1, 2, 3, 4));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Notifications_NotificationType]...';


GO
ALTER TABLE [dbo].[Notifications]
    ADD CONSTRAINT [CK_Notifications_NotificationType] CHECK ([NotificationType] IN (1, 2, 3, 4, 5));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Notifications_Channel]...';


GO
ALTER TABLE [dbo].[Notifications]
    ADD CONSTRAINT [CK_Notifications_Channel] CHECK ([Channel]           IN (1, 2, 3, 4));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Offers_OfferType]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [CK_Offers_OfferType] CHECK ([OfferType]    IN (1, 2, 3));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Offers_ApplicableOn]...';


GO
ALTER TABLE [dbo].[Offers]
    ADD CONSTRAINT [CK_Offers_ApplicableOn] CHECK ([ApplicableOn] IN (1, 2, 3, 4));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Orders_OrderStatus]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [CK_Orders_OrderStatus] CHECK ([OrderStatus]  IN (1, 2, 3, 4, 5, 6, 7));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Orders_PaymentMode]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [CK_Orders_PaymentMode] CHECK ([PaymentMode]  IN (1, 2, 3));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Orders_PaymentStatus]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [CK_Orders_PaymentStatus] CHECK ([PaymentStatus] IN (1, 2, 3, 4));


GO
PRINT N'Creating Check Constraint [dbo].[CK_OtpVerifications_OtpType]...';


GO
ALTER TABLE [dbo].[OtpVerifications]
    ADD CONSTRAINT [CK_OtpVerifications_OtpType] CHECK ([OtpType] IN (1, 2));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Products_ApprovalStatus]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [CK_Products_ApprovalStatus] CHECK ([ApprovalStatus] IN (1, 2, 3));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Reviews_Rating]...';


GO
ALTER TABLE [dbo].[Reviews]
    ADD CONSTRAINT [CK_Reviews_Rating] CHECK ([Rating] BETWEEN 1 AND 5);


GO
PRINT N'Creating Check Constraint [dbo].[CK_SellerDocuments_DocumentType]...';


GO
ALTER TABLE [dbo].[SellerDocuments]
    ADD CONSTRAINT [CK_SellerDocuments_DocumentType] CHECK ([DocumentType] IN (1, 2, 3, 4));


GO
PRINT N'Creating Check Constraint [dbo].[CK_Sellers_ApprovalStatus]...';


GO
ALTER TABLE [dbo].[Sellers]
    ADD CONSTRAINT [CK_Sellers_ApprovalStatus] CHECK ([ApprovalStatus] IN (1, 2, 3, 4));


GO
PRINT N'Creating Check Constraint [dbo].[CK_WalletTransactions_Type]...';


GO
ALTER TABLE [dbo].[WalletTransactions]
    ADD CONSTRAINT [CK_WalletTransactions_Type] CHECK ([TransactionType] IN (1, 2));


GO
PRINT N'Creating Trigger [dbo].[tr_Brands_UpdatedAt]...';


GO
-- Individual AFTER UPDATE triggers to keep UpdatedAt current on all major business tables.
-- SPs always set UpdatedAt explicitly; these triggers act as a safety net for direct DML.

CREATE TRIGGER [dbo].[tr_Brands_UpdatedAt]
ON [dbo].[Brands] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE b SET b.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[Brands] b INNER JOIN inserted i ON b.[BrandId] = i.[BrandId];
END;
GO
PRINT N'Creating Trigger [dbo].[tr_Categories_UpdatedAt]...';


GO

CREATE TRIGGER [dbo].[tr_Categories_UpdatedAt]
ON [dbo].[Categories] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c SET c.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[Categories] c INNER JOIN inserted i ON c.[CategoryId] = i.[CategoryId];
END;
GO
PRINT N'Creating Trigger [dbo].[tr_Orders_Audit]...';


GO
CREATE TRIGGER [dbo].[tr_Orders_Audit]
ON [dbo].[Orders]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Action NVARCHAR(10) = CASE
        WHEN EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted) THEN N'UPDATE'
        WHEN EXISTS (SELECT 1 FROM inserted) THEN N'INSERT'
        ELSE N'DELETE'
    END;

    INSERT INTO [dbo].[AuditLogs]
        ([TableName], [RecordId], [Action], [OldValues], [NewValues], [ChangedBy], [ChangedAt])
    SELECT
        N'Orders',
        COALESCE(i.[OrderId], d.[OrderId]),
        @Action,
        (SELECT d.[OrderStatus], d.[PaymentStatus], d.[TotalAmount], d.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.[OrderStatus], i.[PaymentStatus], i.[TotalAmount], i.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.[OrderId] = i.[OrderId];
END;
GO
PRINT N'Creating Trigger [dbo].[tr_Products_PriceHistory]...';


GO
CREATE TRIGGER [dbo].[tr_Products_PriceHistory]
ON [dbo].[Products]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Only fire when MRP or SellingPrice changes
    IF NOT (UPDATE([MRP]) OR UPDATE([SellingPrice]))
        RETURN;

    INSERT INTO [dbo].[PriceHistory]
        ([ProductId], [OldMRP], [NewMRP], [OldSellingPrice], [NewSellingPrice], [ChangedBy], [ChangedAt], [Reason])
    SELECT
        i.[ProductId],
        d.[MRP],
        i.[MRP],
        d.[SellingPrice],
        i.[SellingPrice],
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE(),
        N'Automatic price change via trigger'
    FROM inserted i
    INNER JOIN deleted d ON d.[ProductId] = i.[ProductId]
    WHERE d.[MRP] <> i.[MRP] OR d.[SellingPrice] <> i.[SellingPrice];
END;
GO
PRINT N'Creating Trigger [dbo].[tr_Products_Audit]...';


GO
CREATE TRIGGER [dbo].[tr_Products_Audit]
ON [dbo].[Products]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Action NVARCHAR(10) = CASE
        WHEN EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted) THEN N'UPDATE'
        WHEN EXISTS (SELECT 1 FROM inserted) THEN N'INSERT'
        ELSE N'DELETE'
    END;

    INSERT INTO [dbo].[AuditLogs]
        ([TableName], [RecordId], [Action], [OldValues], [NewValues], [ChangedBy], [ChangedAt])
    SELECT
        N'Products',
        COALESCE(i.[ProductId], d.[ProductId]),
        @Action,
        (SELECT d.[ApprovalStatus], d.[IsActive], d.[IsDeleted], d.[MRP], d.[SellingPrice] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.[ApprovalStatus], i.[IsActive], i.[IsDeleted], i.[MRP], i.[SellingPrice] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.[ProductId] = i.[ProductId];
END;
GO
PRINT N'Creating Trigger [dbo].[tr_ProductVariants_UpdatedAt]...';


GO

CREATE TRIGGER [dbo].[tr_ProductVariants_UpdatedAt]
ON [dbo].[ProductVariants] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE pv SET pv.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[ProductVariants] pv INNER JOIN inserted i ON pv.[VariantId] = i.[VariantId];
END;
GO
PRINT N'Creating Trigger [dbo].[tr_Sellers_Audit]...';


GO
CREATE TRIGGER [dbo].[tr_Sellers_Audit]
ON [dbo].[Sellers]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Action NVARCHAR(10) = CASE
        WHEN EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted) THEN N'UPDATE'
        WHEN EXISTS (SELECT 1 FROM inserted) THEN N'INSERT'
        ELSE N'DELETE'
    END;

    INSERT INTO [dbo].[AuditLogs]
        ([TableName], [RecordId], [Action], [OldValues], [NewValues], [ChangedBy], [ChangedAt])
    SELECT
        N'Sellers',
        COALESCE(i.[SellerId], d.[SellerId]),
        @Action,
        (SELECT d.[ApprovalStatus], d.[CommissionRate], d.[IsActive], d.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.[ApprovalStatus], i.[CommissionRate], i.[IsActive], i.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.[SellerId] = i.[SellerId];
END;
GO
PRINT N'Creating Trigger [dbo].[tr_SubCategories_UpdatedAt]...';


GO

CREATE TRIGGER [dbo].[tr_SubCategories_UpdatedAt]
ON [dbo].[SubCategories] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE sc SET sc.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[SubCategories] sc INNER JOIN inserted i ON sc.[SubCategoryId] = i.[SubCategoryId];
END;
GO
PRINT N'Creating Trigger [dbo].[tr_UserAddresses_UpdatedAt]...';


GO

CREATE TRIGGER [dbo].[tr_UserAddresses_UpdatedAt]
ON [dbo].[UserAddresses] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ua SET ua.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[UserAddresses] ua INNER JOIN inserted i ON ua.[AddressId] = i.[AddressId];
END;
GO
PRINT N'Creating Trigger [dbo].[tr_Users_Audit]...';


GO
CREATE TRIGGER [dbo].[tr_Users_Audit]
ON [dbo].[Users]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Action NVARCHAR(10) = CASE
        WHEN EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted) THEN N'UPDATE'
        WHEN EXISTS (SELECT 1 FROM inserted) THEN N'INSERT'
        ELSE N'DELETE'
    END;

    INSERT INTO [dbo].[AuditLogs]
        ([TableName], [RecordId], [Action], [OldValues], [NewValues], [ChangedBy], [ChangedAt])
    SELECT
        N'Users',
        COALESCE(i.[UserId], d.[UserId]),
        @Action,
        (SELECT d.[Email], d.[RoleId], d.[IsApproved], d.[IsActive], d.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.[Email], i.[RoleId], i.[IsApproved], i.[IsActive], i.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.[UserId] = i.[UserId];
END;
GO
PRINT N'Creating View [dbo].[vw_ActiveOffers]...';


GO
CREATE VIEW [dbo].[vw_ActiveOffers]
AS
SELECT
    o.[OfferId],
    o.[OfferName],
    o.[OfferType],
    o.[DiscountValue],
    o.[MinOrderValue],
    o.[MaxDiscountCap],
    o.[StartDate],
    o.[EndDate],
    o.[ApplicableOn],
    o.[EntityId],
    o.[UsageLimitTotal],
    o.[UsageLimitPerUser],
    o.[CurrentUsageCount],

    -- Associated coupon code (if any)
    cp.[CouponId],
    cp.[CouponCode]

FROM [dbo].[Offers]   o
LEFT JOIN [dbo].[Coupons] cp ON cp.[OfferId] = o.[OfferId] AND cp.[IsDeleted] = 0 AND cp.[IsActive] = 1

WHERE
    o.[IsDeleted]  = 0
    AND o.[IsActive]  = 1
    AND o.[StartDate] <= GETUTCDATE()
    AND o.[EndDate]   >= GETUTCDATE()
    AND (o.[UsageLimitTotal] IS NULL OR o.[CurrentUsageCount] < o.[UsageLimitTotal]);
GO
PRINT N'Creating View [dbo].[vw_CartDetails]...';


GO
CREATE VIEW [dbo].[vw_CartDetails]
AS
SELECT
    c.[CartId],
    c.[UserId],
    c.[Quantity],
    c.[SavedForLater],
    c.[AddedAt],

    -- Product
    p.[ProductId],
    p.[ProductName],
    p.[SlugUrl]           AS [ProductSlug],
    p.[MRP],
    p.[SellingPrice],
    p.[GstRate],
    p.[IsCODAvailable],
    p.[IsReturnable],
    p.[ApprovalStatus]    AS [ProductApprovalStatus],
    p.[IsActive]          AS [ProductIsActive],

    -- Variant
    pv.[VariantId],
    pv.[Color],
    pv.[ColorHexCode],
    pv.[Size],
    pv.[Material],
    pv.[VariantSku],
    pv.[AdditionalPrice],
    pv.[StockQuantity],
    pv.[LowStockThreshold],
    (p.[SellingPrice] + pv.[AdditionalPrice]) AS [FinalPrice],

    -- Brand
    b.[BrandId],
    b.[BrandName],

    -- Primary image
    pi_.[ImageUrl]        AS [PrimaryImageUrl]

FROM [dbo].[Cart]               c
INNER JOIN [dbo].[Products]        p   ON p.[ProductId]  = c.[ProductId]  AND p.[IsDeleted]  = 0
INNER JOIN [dbo].[ProductVariants] pv  ON pv.[VariantId] = c.[VariantId]  AND pv.[IsDeleted] = 0
INNER JOIN [dbo].[Brands]          b   ON b.[BrandId]    = p.[BrandId]    AND b.[IsDeleted]  = 0
LEFT  JOIN [dbo].[ProductImages]   pi_ ON pi_.[ProductId] = p.[ProductId] AND pi_.[IsPrimary] = 1
                                       AND pi_.[IsDeleted] = 0

WHERE c.[IsDeleted] = 0;
GO
PRINT N'Creating View [dbo].[vw_OrderDetails]...';


GO
CREATE VIEW [dbo].[vw_OrderDetails]
AS
SELECT
    o.[OrderId],
    o.[OrderNumber],
    o.[OrderStatus],
    o.[SubTotal],
    o.[DiscountAmount],
    o.[CouponDiscount],
    o.[TaxAmount],
    o.[ShippingCharge],
    o.[TotalAmount],
    o.[PaymentMode],
    o.[PaymentStatus],
    o.[ExpectedDeliveryDate],
    o.[DeliveredAt],
    o.[CancelledAt],
    o.[CancellationReason],
    o.[CreatedAt]           AS [OrderDate],

    -- Buyer
    u.[UserId],
    u.[Email]               AS [BuyerEmail],
    u.[FirstName]           AS [BuyerFirstName],
    u.[LastName]            AS [BuyerLastName],

    -- Shipping Address
    ua.[AddressLine1],
    ua.[AddressLine2],
    ua.[City],
    ua.[State],
    ua.[PinCode],
    ua.[Country],

    -- Coupon (if any)
    cp.[CouponCode],

    -- Order Items
    oi.[OrderItemId],
    oi.[ProductId],
    oi.[VariantId],
    oi.[SellerId],
    oi.[BrandId],
    oi.[ProductName],
    oi.[VariantSnapshot],
    oi.[Quantity],
    oi.[UnitPrice],
    oi.[DiscountAmount]     AS [ItemDiscountAmount],
    oi.[TaxAmount]          AS [ItemTaxAmount],
    oi.[TotalPrice],
    oi.[CommissionAmount],
    oi.[SellerEarning],
    oi.[IsReturned]

FROM [dbo].[Orders]        o
INNER JOIN [dbo].[Users]           u   ON u.[UserId]    = o.[UserId]            AND u.[IsDeleted]    = 0
INNER JOIN [dbo].[UserAddresses]   ua  ON ua.[AddressId] = o.[ShippingAddressId]
INNER JOIN [dbo].[OrderItems]      oi  ON oi.[OrderId]   = o.[OrderId]          AND oi.[IsDeleted]   = 0
LEFT  JOIN [dbo].[Coupons]         cp  ON cp.[CouponId]  = o.[CouponId]

WHERE o.[IsDeleted] = 0;
GO
PRINT N'Creating View [dbo].[vw_ProductListing]...';


GO
CREATE VIEW [dbo].[vw_ProductListing]
AS
SELECT
    p.[ProductId],
    p.[ProductName],
    p.[SlugUrl],
    p.[ShortDescription],
    p.[MRP],
    p.[SellingPrice],
    p.[GstRate],
    p.[Sku],
    p.[IsFeatured],
    p.[SortOrder],
    p.[ApprovalStatus],
    p.[IsActive],
    p.[IsDeleted],
    p.[PublishedAt],

    -- Brand
    b.[BrandId],
    b.[BrandName],
    b.[SlugUrl]          AS [BrandSlug],
    b.[LogoUrl]          AS [BrandLogoUrl],

    -- Category / SubCategory
    c.[CategoryId],
    c.[CategoryName],
    c.[SlugUrl]          AS [CategorySlug],
    sc.[SubCategoryId],
    sc.[SubCategoryName],
    sc.[SlugUrl]         AS [SubCategorySlug],

    -- Gender
    gt.[GenderTypeId],
    gt.[Name]            AS [GenderType],

    -- Seller
    s.[SellerId],
    s.[BusinessName]     AS [SellerName],

    -- Primary image
    pi_.[ImageUrl]       AS [PrimaryImageUrl],
    pi_.[AltText]        AS [PrimaryImageAlt],

    -- Stock (minimum across all active variants)
    ISNULL(vs.[MinStock], 0) AS [MinStockQuantity],
    ISNULL(vs.[VariantCount], 0) AS [VariantCount]

FROM [dbo].[Products]               p
INNER JOIN [dbo].[Brands]           b   ON b.[BrandId]       = p.[BrandId]       AND b.[IsDeleted] = 0
INNER JOIN [dbo].[Categories]       c   ON c.[CategoryId]    = p.[CategoryId]    AND c.[IsDeleted] = 0
INNER JOIN [dbo].[SubCategories]    sc  ON sc.[SubCategoryId] = p.[SubCategoryId] AND sc.[IsDeleted] = 0
INNER JOIN [dbo].[Sellers]          s   ON s.[SellerId]       = p.[SellerId]      AND s.[IsDeleted] = 0
LEFT  JOIN [dbo].[GenderTypes]      gt  ON gt.[GenderTypeId]  = p.[GenderTypeId]
LEFT  JOIN [dbo].[ProductImages]    pi_ ON pi_.[ProductId]    = p.[ProductId]
                                       AND pi_.[IsPrimary]    = 1
                                       AND pi_.[IsDeleted]    = 0
LEFT  JOIN (
    SELECT
        [ProductId],
        MIN([StockQuantity])   AS [MinStock],
        COUNT([VariantId])     AS [VariantCount]
    FROM [dbo].[ProductVariants]
    WHERE [IsDeleted] = 0 AND [IsActive] = 1
    GROUP BY [ProductId]
) vs ON vs.[ProductId] = p.[ProductId]

WHERE p.[IsDeleted] = 0;
GO
PRINT N'Creating View [dbo].[vw_SellerSummary]...';


GO
CREATE VIEW [dbo].[vw_SellerSummary]
AS
SELECT
    s.[SellerId],
    s.[BusinessName],
    s.[GstNumber],
    s.[PanNumber],
    s.[ApprovalStatus],
    s.[CommissionRate],
    s.[IsActive],

    -- User info
    u.[UserId],
    u.[Email],
    u.[FirstName],
    u.[LastName],
    u.[Mobile],
    u.[ProfileImageUrl],

    -- Business address
    ua.[AddressLine1],
    ua.[City],
    ua.[State],
    ua.[PinCode],

    -- Counts
    ISNULL(pc.[ProductCount], 0)          AS [TotalProducts],
    ISNULL(bm.[BrandCount], 0)            AS [ApprovedBrandCount]

FROM [dbo].[Sellers]        s
INNER JOIN [dbo].[Users]          u   ON u.[UserId]    = s.[UserId]            AND u.[IsDeleted]  = 0
LEFT  JOIN [dbo].[UserAddresses]  ua  ON ua.[AddressId] = s.[BusinessAddressId]
LEFT  JOIN (
    SELECT [SellerId], COUNT([ProductId]) AS [ProductCount]
    FROM [dbo].[Products]
    WHERE [IsDeleted] = 0 AND [ApprovalStatus] = 2
    GROUP BY [SellerId]
) pc ON pc.[SellerId] = s.[SellerId]
LEFT  JOIN (
    SELECT [SellerId], COUNT([MappingId]) AS [BrandCount]
    FROM [dbo].[SellerBrandMappings]
    WHERE [IsDeleted] = 0 AND [IsApproved] = 1
    GROUP BY [SellerId]
) bm ON bm.[SellerId] = s.[SellerId]

WHERE s.[IsDeleted] = 0;
GO
PRINT N'Creating Function [dbo].[fn_CalculateDiscountedPrice]...';


GO
CREATE FUNCTION [dbo].[fn_CalculateDiscountedPrice]
(
    @BasePrice     DECIMAL(18,2),
    @OfferType     TINYINT,        -- 1=Flat, 2=Percentage, 3=BOGO(treat as 0)
    @DiscountValue DECIMAL(18,2),
    @MaxDiscountCap DECIMAL(18,2)  -- NULL = no cap
)
RETURNS DECIMAL(18,2)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @Discount DECIMAL(18,2) = 0;

    IF @OfferType = 1        -- Flat
        SET @Discount = @DiscountValue;
    ELSE IF @OfferType = 2   -- Percentage
    BEGIN
        SET @Discount = @BasePrice * @DiscountValue / 100;
        IF @MaxDiscountCap IS NOT NULL AND @Discount > @MaxDiscountCap
            SET @Discount = @MaxDiscountCap;
    END;
    -- BOGO handled at order-placement level, not here

    DECLARE @FinalPrice DECIMAL(18,2) = @BasePrice - @Discount;
    RETURN CASE WHEN @FinalPrice < 0 THEN 0 ELSE @FinalPrice END;
END;
GO
PRINT N'Creating Function [dbo].[fn_GenerateOrderNumber]...';


GO
CREATE FUNCTION [dbo].[fn_GenerateOrderNumber]
(
    @OrderId INT
)
RETURNS NVARCHAR(50)
WITH SCHEMABINDING
AS
BEGIN
    -- Format: SNS-YYYYMMDD-NNNNN  e.g. SNS-20240315-00042
    RETURN N'SNS-' + FORMAT(GETUTCDATE(), 'yyyyMMdd') + N'-' + RIGHT(N'00000' + CAST(@OrderId AS NVARCHAR(5)), 5);
END;
GO
PRINT N'Creating Function [dbo].[fn_GenerateSlug]...';


GO
CREATE FUNCTION [dbo].[fn_GenerateSlug]
(
    @InputText NVARCHAR(400)
)
RETURNS NVARCHAR(400)
WITH SCHEMABINDING
AS
BEGIN
    -- Convert to lower-case, replace spaces/special chars with hyphens
    DECLARE @Slug NVARCHAR(400) = LOWER(@InputText);

    -- Replace common special chars with hyphen
    SET @Slug = REPLACE(@Slug, N' ',  N'-');
    SET @Slug = REPLACE(@Slug, N'/',  N'-');
    SET @Slug = REPLACE(@Slug, N'&',  N'and');
    SET @Slug = REPLACE(@Slug, N'''', N'');
    SET @Slug = REPLACE(@Slug, N'"',  N'');
    SET @Slug = REPLACE(@Slug, N',',  N'');
    SET @Slug = REPLACE(@Slug, N'.',  N'');
    SET @Slug = REPLACE(@Slug, N'(',  N'');
    SET @Slug = REPLACE(@Slug, N')',  N'');

    -- Collapse consecutive hyphens
    WHILE CHARINDEX(N'--', @Slug) > 0
        SET @Slug = REPLACE(@Slug, N'--', N'-');

    -- Trim leading/trailing hyphens
    SET @Slug = LTRIM(RTRIM(@Slug));
    IF LEFT(@Slug,  1) = N'-' SET @Slug = RIGHT(@Slug, LEN(@Slug) - 1);
    IF RIGHT(@Slug, 1) = N'-' SET @Slug = LEFT(@Slug,  LEN(@Slug) - 1);

    RETURN @Slug;
END;
GO
PRINT N'Creating Procedure [dbo].[sp_GetBanners]...';


GO
CREATE PROCEDURE [dbo].[sp_GetBanners]
    @Section TINYINT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            b.[BannerId]              AS [Id],
            b.[BannerType]            AS [Section],
            b.[ImageUrl],
            b.[MobileImageUrl],
            b.[Title],
            b.[SubTitle]              AS [Subtitle],
            b.[LinkUrl],
            b.[SortOrder]
        FROM [dbo].[Banners] b
        WHERE b.[IsDeleted]  = 0
          AND b.[IsActive]   = 1
          AND b.[BannerType] = @Section
          AND (b.[StartDate] IS NULL OR b.[StartDate] <= GETUTCDATE())
          AND (b.[EndDate]   IS NULL OR b.[EndDate]   >= GETUTCDATE())
        ORDER BY b.[SortOrder] ASC, b.[BannerId] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[sp_GetMegaMenu]...';


GO
CREATE PROCEDURE [dbo].[sp_GetMegaMenu]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- 3-level commerce hierarchy:
        -- Level 1: Menus (MEN, WOMEN, KIDS, HOME, BEAUTY, HOMESTOP, GIFTS, WATCHES, PERFUMES, BRANDS)
        -- Level 2: Categories (e.g., Casual Wear, Inner Wear, Formal Wear under MEN)
        -- Level 3: SubCategories (e.g., T-Shirts, Polos, Shirts under Casual Wear)
        SELECT
            m.[MenuId]                      AS [TopMenuId],
            m.[MenuName]                    AS [TopMenuName],
            m.[SlugUrl]                     AS [TopMenuSlug],

            c.[CategoryId]                  AS [SubMenuId],
            c.[CategoryName]                AS [SubMenuName],
            c.[SlugUrl]                     AS [SubMenuSlug],

            sc.[SubCategoryId]              AS [SubSubMenuId],
            sc.[SubCategoryName]            AS [SubSubMenuName],
            sc.[SlugUrl]                    AS [SubSubMenuSlug]
        FROM [dbo].[Menus]          m
        INNER JOIN [dbo].[Categories]    c
              ON c.[MenuId] = m.[MenuId]
             AND c.[IsDeleted] = 0 AND c.[IsActive] = 1
        INNER JOIN [dbo].[SubCategories] sc
              ON sc.[CategoryId] = c.[CategoryId]
             AND sc.[IsDeleted] = 0 AND sc.[IsActive] = 1
        WHERE m.[IsDeleted] = 0
          AND m.[IsActive]  = 1
        ORDER BY m.[SortOrder], m.[MenuName], c.[SortOrder], c.[CategoryName], sc.[SortOrder], sc.[SubCategoryName];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[sp_GetStores]...';


GO
CREATE PROCEDURE [dbo].[sp_GetStores]
    @City NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            s.[StoreId]    AS [Id],
            s.[StoreName]  AS [Name],
            s.[Address],
            s.[City],
            s.[State],
            s.[Pincode],
            s.[Lat],
            s.[Lng],
            s.[Phone]
        FROM [dbo].[Stores] s
        WHERE s.[IsDeleted] = 0
          AND s.[IsActive]  = 1
          AND (@City IS NULL OR s.[City] = @City)
        ORDER BY s.[City] ASC, s.[StoreName] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[sp_SellerCompleteOnboarding]...';


GO
CREATE PROCEDURE [dbo].[sp_SellerCompleteOnboarding]
    @SellerId           INT,
    @OwnerFullName      NVARCHAR(200),
    @DisplayName        NVARCHAR(200),
    @StoreDescription   NVARCHAR(MAX),
    @IsPhoneVerified    BIT,
    @IsEmailVerified    BIT,
    @IsIdVerified       BIT,
    @SelectedCategories NVARCHAR(MAX) = NULL,
    @PickupAddressLine1 NVARCHAR(300) = NULL,
    @PickupAddressLine2 NVARCHAR(300) = NULL,
    @PickupCity         NVARCHAR(100) = NULL,
    @PickupState        NVARCHAR(100) = NULL,
    @PickupPincode      NVARCHAR(10)  = NULL,
    @PickupLandmark     NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @UserId INT;
        SELECT @UserId = [UserId]
        FROM   [dbo].[Sellers]
        WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0;

        IF @UserId IS NULL
            THROW 50095, N'Seller not found.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[Sellers]
            SET
                [OwnerName]           = @OwnerFullName,
                [DisplayName]         = @DisplayName,
                [StoreDescription]    = @StoreDescription,
                [IsIdVerified]        = @IsIdVerified,
                [OnboardingCompleted] = 1,
                [SelectedCategories]  = @SelectedCategories,
                [PickupAddressLine1]  = @PickupAddressLine1,
                [PickupAddressLine2]  = @PickupAddressLine2,
                [PickupCity]          = @PickupCity,
                [PickupState]         = @PickupState,
                [PickupPincode]       = @PickupPincode,
                [PickupLandmark]      = @PickupLandmark,
                [UpdatedAt]           = GETUTCDATE(),
                [UpdatedBy]           = @SellerId
            WHERE [SellerId] = @SellerId;

            UPDATE [dbo].[Users]
            SET
                [IsMobileVerified] = @IsPhoneVerified,
                [IsEmailVerified]  = @IsEmailVerified,
                [UpdatedAt]        = GETUTCDATE()
            WHERE [UserId] = @UserId;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[sp_SellerGetProfile]...';


GO
CREATE PROCEDURE [dbo].[sp_SellerGetProfile]
    @SellerId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.[SellerId]                                                     AS [Id],
        NULLIF(s.[BusinessName], N'')                                    AS [BusinessName],
        s.[OwnerName],
        u.[Email],
        u.[Mobile]                                                       AS [PhoneNumber],
        s.[GstNumber]                                                    AS [GSTNumber],
        s.[Address],
        s.[City],
        s.[State],
        s.[Pincode],
        s.[DisplayName],
        s.[StoreDescription],
        s.[BannerUrl],
        s.[LogoUrl],
        s.[SupportEmail],
        s.[SupportPhone],
        s.[Description],
        u.[IsMobileVerified]                                             AS [IsPhoneVerified],
        u.[IsEmailVerified],
        s.[IsIdVerified],
        s.[OnboardingCompleted],
        s.[PickupAddressLine1],
        s.[PickupAddressLine2],
        s.[PickupCity],
        s.[PickupState],
        s.[PickupPincode],
        s.[PickupLandmark],
        s.[SelectedCategories],
        s.[IsActive],
        CAST(CASE WHEN s.[ApprovalStatus] = 2 THEN 1 ELSE 0 END AS BIT) AS [IsApproved],
        s.[CreatedAt],
        s.[UpdatedAt]
    FROM [dbo].[Sellers] s
    INNER JOIN [dbo].[Users] u ON u.[UserId] = s.[UserId]
    WHERE s.[SellerId]  = @SellerId
      AND s.[IsDeleted] = 0;
END;
GO
PRINT N'Creating Procedure [dbo].[sp_SellerLogin]...';


GO
CREATE PROCEDURE [dbo].[sp_SellerLogin]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @UserId INT;
        DECLARE @RoleId INT;

        -- First check if user exists and get their role
        SELECT @UserId = [UserId], @RoleId = [RoleId]
        FROM   [dbo].[Users]
        WHERE  [Email]     = @Email
          AND  [IsDeleted] = 0
          AND  [IsActive]  = 1;

        IF @UserId IS NULL
            THROW 50003, N'User not found or account is inactive.', 1;

        -- Validate that user is a Seller (RoleId = 3)
        IF @RoleId != 3
            THROW 50005, N'This account is not a seller account. Please use the appropriate login page.', 1;

        -- Check if seller profile exists
        DECLARE @SellerId INT;
        SELECT @SellerId = [SellerId]
        FROM [dbo].[Sellers]
        WHERE [UserId] = @UserId
          AND [IsDeleted] = 0;

        IF @SellerId IS NULL
            THROW 50006, N'Seller profile not found. Please complete your seller registration.', 1;

        SELECT
            s.[SellerId]                                                     AS [Id],
            NULLIF(s.[BusinessName], N'')                                    AS [BusinessName],
            s.[OwnerName],
            u.[Email],
            u.[Mobile]                                                       AS [PhoneNumber],
            s.[GstNumber]                                                    AS [GSTNumber],
            s.[Address],
            s.[City],
            s.[State],
            s.[Pincode],
            s.[DisplayName],
            s.[StoreDescription],
            s.[BannerUrl],
            s.[LogoUrl],
            s.[SupportEmail],
            s.[SupportPhone],
            s.[Description],
            u.[IsMobileVerified]                                             AS [IsPhoneVerified],
            u.[IsEmailVerified],
            s.[IsIdVerified],
            s.[OnboardingCompleted],
            s.[PickupAddressLine1],
            s.[PickupAddressLine2],
            s.[PickupCity],
            s.[PickupState],
            s.[PickupPincode],
            s.[PickupLandmark],
            s.[SelectedCategories],
            s.[IsActive],
            CAST(CASE WHEN s.[ApprovalStatus] = 2 THEN 1 ELSE 0 END AS BIT) AS [IsApproved],
            s.[CreatedAt],
            s.[UpdatedAt],
            u.[PasswordHash]
        FROM [dbo].[Sellers] s
        INNER JOIN [dbo].[Users] u ON u.[UserId] = s.[UserId]
        WHERE u.[Email]     = @Email
          AND u.[IsDeleted] = 0
          AND s.[IsDeleted] = 0;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[sp_SellerSignup]...';


GO
CREATE PROCEDURE [dbo].[sp_SellerSignup]
    @Email        NVARCHAR(256),
    @PhoneNumber  NVARCHAR(15),
    @PasswordHash NVARCHAR(500),
    @SellerId     INT          OUTPUT,
    @ErrorCode    NVARCHAR(50) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @SellerId  = 0;
    SET @ErrorCode = NULL;

    BEGIN TRY
        -- Duplicate email check
        IF EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [Email] = @Email AND [IsDeleted] = 0)
        BEGIN
            SET @ErrorCode = 'EMAIL_EXISTS';
            RETURN;
        END;

        BEGIN TRANSACTION;

            DECLARE @NewUserId INT;

            INSERT INTO [dbo].[Users]
                ([Email], [PasswordHash], [Mobile], [RoleId], [IsApproved], [ReferralCode])
            VALUES
                (@Email, @PasswordHash, @PhoneNumber, 3, 0,
                 UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''), 8)));

            SET @NewUserId = SCOPE_IDENTITY();

            INSERT INTO [dbo].[Sellers]
                ([UserId], [BusinessName], [ApprovalStatus], [CreatedBy], [UpdatedBy])
            VALUES
                (@NewUserId, N'', 1, @NewUserId, @NewUserId);

            SET @SellerId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[sp_SellerUpdateProfile]...';


GO
CREATE PROCEDURE [dbo].[sp_SellerUpdateProfile]
    @SellerId     INT,
    @BusinessName NVARCHAR(300) = NULL,
    @OwnerName    NVARCHAR(200) = NULL,
    @PhoneNumber  NVARCHAR(15)  = NULL,
    @GSTNumber    NVARCHAR(20)  = NULL,
    @Address      NVARCHAR(300) = NULL,
    @City         NVARCHAR(100) = NULL,
    @State        NVARCHAR(100) = NULL,
    @Pincode      NVARCHAR(10)  = NULL,
    @BannerUrl    NVARCHAR(500) = NULL,
    @LogoUrl      NVARCHAR(500) = NULL,
    @SupportEmail NVARCHAR(256) = NULL,
    @SupportPhone NVARCHAR(20)  = NULL,
    @Description  NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @UserId INT;
        SELECT @UserId = [UserId]
        FROM   [dbo].[Sellers]
        WHERE  [SellerId] = @SellerId AND [IsDeleted] = 0;

        IF @UserId IS NULL
            THROW 50095, N'Seller not found.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[Sellers]
            SET
                [BusinessName] = ISNULL(@BusinessName, [BusinessName]),
                [OwnerName]    = ISNULL(@OwnerName,    [OwnerName]),
                [GstNumber]    = ISNULL(@GSTNumber,    [GstNumber]),
                [Address]      = ISNULL(@Address,      [Address]),
                [City]         = ISNULL(@City,         [City]),
                [State]        = ISNULL(@State,        [State]),
                [Pincode]      = ISNULL(@Pincode,      [Pincode]),
                [BannerUrl]    = ISNULL(@BannerUrl,    [BannerUrl]),
                [LogoUrl]      = ISNULL(@LogoUrl,      [LogoUrl]),
                [SupportEmail] = ISNULL(@SupportEmail, [SupportEmail]),
                [SupportPhone] = ISNULL(@SupportPhone, [SupportPhone]),
                [Description]  = ISNULL(@Description,  [Description]),
                [UpdatedAt]    = GETUTCDATE(),
                [UpdatedBy]    = @SellerId
            WHERE [SellerId] = @SellerId;

            IF @PhoneNumber IS NOT NULL
                UPDATE [dbo].[Users]
                SET    [Mobile]    = @PhoneNumber,
                       [UpdatedAt] = GETUTCDATE()
                WHERE  [UserId] = @UserId;

        COMMIT TRANSACTION;

        -- Return updated profile
        SELECT
            s.[SellerId]                                                     AS [Id],
            NULLIF(s.[BusinessName], N'')                                    AS [BusinessName],
            s.[OwnerName],
            u.[Email],
            u.[Mobile]                                                       AS [PhoneNumber],
            s.[GstNumber]                                                    AS [GSTNumber],
            s.[Address],
            s.[City],
            s.[State],
            s.[Pincode],
            s.[DisplayName],
            s.[StoreDescription],
            s.[BannerUrl],
            s.[LogoUrl],
            s.[SupportEmail],
            s.[SupportPhone],
            s.[Description],
            u.[IsMobileVerified]                                             AS [IsPhoneVerified],
            u.[IsEmailVerified],
            s.[IsIdVerified],
            s.[OnboardingCompleted],
            s.[PickupAddressLine1],
            s.[PickupAddressLine2],
            s.[PickupCity],
            s.[PickupState],
            s.[PickupPincode],
            s.[PickupLandmark],
            s.[SelectedCategories],
            s.[IsActive],
            CAST(CASE WHEN s.[ApprovalStatus] = 2 THEN 1 ELSE 0 END AS BIT) AS [IsApproved],
            s.[CreatedAt],
            s.[UpdatedAt]
        FROM [dbo].[Sellers] s
        INNER JOIN [dbo].[Users] u ON u.[UserId] = s.[UserId]
        WHERE s.[SellerId] = @SellerId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Admin_Dashboard_GetStats]...';


GO
CREATE PROCEDURE [dbo].[usp_Admin_Dashboard_GetStats]
    @FromDate DATE = NULL,
    @ToDate   DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @FromDate = COALESCE(@FromDate, DATEADD(DAY, -29, CAST(GETUTCDATE() AS DATE)));
        SET @ToDate   = COALESCE(@ToDate,   CAST(GETUTCDATE() AS DATE));

        -- Platform summary
        SELECT
            (SELECT COUNT(*) FROM [dbo].[Users]    WHERE [IsDeleted] = 0 AND [RoleId] = 2) AS [TotalBuyers],
            (SELECT COUNT(*) FROM [dbo].[Sellers]  WHERE [IsDeleted] = 0)                  AS [TotalSellers],
            (SELECT COUNT(*) FROM [dbo].[Sellers]  WHERE [IsDeleted] = 0 AND [ApprovalStatus] = 1) AS [PendingSellerApprovals],
            (SELECT COUNT(*) FROM [dbo].[Products] WHERE [IsDeleted] = 0)                  AS [TotalProducts],
            (SELECT COUNT(*) FROM [dbo].[Products] WHERE [IsDeleted] = 0 AND [ApprovalStatus] = 1) AS [PendingProductApprovals],
            (SELECT COUNT(*) FROM [dbo].[Orders]   WHERE [IsDeleted] = 0
              AND CAST([CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate) AS [TotalOrders],
            (SELECT ISNULL(SUM([TotalAmount]), 0)
             FROM [dbo].[Orders]
             WHERE [IsDeleted] = 0 AND [OrderStatus] NOT IN (6, 7)
               AND CAST([CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate) AS [TotalRevenue];

        -- Daily order trend
        SELECT
            CAST(o.[CreatedAt] AS DATE)        AS [OrderDate],
            COUNT(*)                           AS [OrderCount],
            ISNULL(SUM(o.[TotalAmount]), 0)    AS [DailyRevenue]
        FROM [dbo].[Orders] o
        WHERE o.[IsDeleted] = 0
          AND o.[OrderStatus] NOT IN (6, 7)
          AND CAST(o.[CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate
        GROUP BY CAST(o.[CreatedAt] AS DATE)
        ORDER BY CAST(o.[CreatedAt] AS DATE) ASC;

        -- Top 5 sellers by revenue
        SELECT TOP 5
            s.[SellerId],
            s.[BusinessName],
            u.[Email],
            SUM(oi.[SellerEarning]) AS [TotalEarnings],
            COUNT(DISTINCT o.[OrderId]) AS [TotalOrders]
        FROM [dbo].[OrderItems]  oi
        INNER JOIN [dbo].[Orders]   o  ON o.[OrderId]  = oi.[OrderId]
        INNER JOIN [dbo].[Sellers]  s  ON s.[SellerId] = oi.[SellerId]
        INNER JOIN [dbo].[Users]    u  ON u.[UserId]   = s.[UserId]
        WHERE oi.[IsDeleted] = 0 AND o.[IsDeleted] = 0
          AND o.[OrderStatus] NOT IN (6, 7)
          AND CAST(o.[CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate
        GROUP BY s.[SellerId], s.[BusinessName], u.[Email]
        ORDER BY SUM(oi.[SellerEarning]) DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Admin_Order_GetAll]...';


GO
CREATE PROCEDURE [dbo].[usp_Admin_Order_GetAll]
    @OrderStatus  TINYINT       = NULL,
    @FromDate     DATE          = NULL,
    @ToDate       DATE          = NULL,
    @SearchTerm   NVARCHAR(200) = NULL,
    @PageNumber   INT = 1,
    @PageSize     INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            o.[OrderId],
            o.[OrderNumber],
            o.[OrderStatus],
            o.[TotalAmount],
            o.[PaymentMode],
            o.[PaymentStatus],
            o.[CreatedAt]  AS [OrderDate],
            u.[FirstName],
            u.[LastName],
            u.[Email],
            COUNT(oi.[OrderItemId]) AS [ItemCount],
            COUNT(*)        OVER()  AS [TotalCount]
        FROM [dbo].[Orders]      o
        INNER JOIN [dbo].[Users]      u  ON u.[UserId]  = o.[UserId]
        INNER JOIN [dbo].[OrderItems] oi ON oi.[OrderId] = o.[OrderId] AND oi.[IsDeleted] = 0
        WHERE o.[IsDeleted] = 0
          AND (@OrderStatus IS NULL OR o.[OrderStatus]                 = @OrderStatus)
          AND (@FromDate    IS NULL OR CAST(o.[CreatedAt] AS DATE)    >= @FromDate)
          AND (@ToDate      IS NULL OR CAST(o.[CreatedAt] AS DATE)    <= @ToDate)
          AND (@SearchTerm  IS NULL  OR o.[OrderNumber] LIKE N'%' + @SearchTerm + N'%'
                                    OR u.[Email]        LIKE N'%' + @SearchTerm + N'%'
                                    OR u.[FirstName]    LIKE N'%' + @SearchTerm + N'%'
                                    OR u.[LastName]     LIKE N'%' + @SearchTerm + N'%')
        GROUP BY
            o.[OrderId], o.[OrderNumber], o.[OrderStatus], o.[TotalAmount],
            o.[PaymentMode], o.[PaymentStatus], o.[CreatedAt],
            u.[FirstName], u.[LastName], u.[Email]
        ORDER BY o.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Admin_Product_Approve]...';


GO
CREATE PROCEDURE [dbo].[usp_Admin_Product_Approve]
    @ProductId  INT,
    @UpdatedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50125, N'Product not found.', 1;

        UPDATE [dbo].[Products]
        SET    [ApprovalStatus] = 2,  -- Approved
               [IsActive]       = 1,
               [UpdatedAt]      = GETUTCDATE(),
               [UpdatedBy]      = @UpdatedBy
        WHERE  [ProductId] = @ProductId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Admin_Product_Reject]...';


GO
CREATE PROCEDURE [dbo].[usp_Admin_Product_Reject]
    @ProductId      INT,
    @RejectReason   NVARCHAR(500) = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50130, N'Product not found.', 1;

        UPDATE [dbo].[Products]
        SET    [ApprovalStatus]  = 3,  -- Rejected
               [IsActive]        = 0,
               [RejectionReason] = @RejectReason,
               [UpdatedAt]       = GETUTCDATE(),
               [UpdatedBy]       = @UpdatedBy
        WHERE  [ProductId] = @ProductId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Admin_Seller_Approve]...';


GO
CREATE PROCEDURE [dbo].[usp_Admin_Seller_Approve]
    @SellerId   INT,
    @UpdatedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
            THROW 50110, N'Seller not found.', 1;

        UPDATE [dbo].[Sellers]
        SET    [ApprovalStatus] = 2,  -- Approved
               [IsActive]       = 1,
               [UpdatedAt]      = GETUTCDATE(),
               [UpdatedBy]      = @UpdatedBy
        WHERE  [SellerId] = @SellerId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Admin_Seller_Reject]...';


GO
CREATE PROCEDURE [dbo].[usp_Admin_Seller_Reject]
    @SellerId       INT,
    @RejectReason   NVARCHAR(500) = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
            THROW 50115, N'Seller not found.', 1;

        UPDATE [dbo].[Sellers]
        SET    [ApprovalStatus] = 3,  -- Rejected
               [IsActive]       = 0,
               [RejectionReason] = @RejectReason,
               [UpdatedAt]      = GETUTCDATE(),
               [UpdatedBy]      = @UpdatedBy
        WHERE  [SellerId] = @SellerId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Admin_Seller_Suspend]...';


GO
CREATE PROCEDURE [dbo].[usp_Admin_Seller_Suspend]
    @SellerId       INT,
    @SuspendReason  NVARCHAR(500) = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
            THROW 50120, N'Seller not found.', 1;

        UPDATE [dbo].[Sellers]
        SET    [IsActive]        = 0,
               [RejectionReason] = @SuspendReason,
               [UpdatedAt]       = GETUTCDATE(),
               [UpdatedBy]       = @UpdatedBy
        WHERE  [SellerId] = @SellerId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Admin_User_GetAll]...';


GO
CREATE PROCEDURE [dbo].[usp_Admin_User_GetAll]
    @RoleId      TINYINT       = NULL,
    @SearchTerm  NVARCHAR(200) = NULL,
    @IsActive    BIT           = NULL,
    @PageNumber  INT = 1,
    @PageSize    INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            u.[UserId],
            u.[FirstName],
            u.[LastName],
            u.[Email],
            u.[Mobile],
            u.[RoleId],
            r.[RoleName],
            u.[IsEmailVerified],
            u.[IsMobileVerified],
            u.[IsActive],
            u.[CreatedAt],
            u.[LastLoginAt],
            COUNT(*) OVER() AS [TotalCount]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[IsDeleted] = 0
          AND (@RoleId     IS NULL OR u.[RoleId]  = @RoleId)
          AND (@IsActive   IS NULL OR u.[IsActive] = @IsActive)
          AND (@SearchTerm IS NULL  OR u.[FirstName] LIKE N'%' + @SearchTerm + N'%'
                                   OR u.[LastName]  LIKE N'%' + @SearchTerm + N'%'
                                   OR u.[Email]     LIKE N'%' + @SearchTerm + N'%'
                                   OR u.[Mobile]    LIKE N'%' + @SearchTerm + N'%')
        ORDER BY u.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_Address_Add]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_Address_Add]
    @UserId       INT,
    @Label        NVARCHAR(50)  = NULL,
    @AddressLine1 NVARCHAR(300),
    @AddressLine2 NVARCHAR(300) = NULL,
    @City         NVARCHAR(100),
    @State        NVARCHAR(100),
    @PinCode      NVARCHAR(10),
    @Country      NVARCHAR(100) = N'India',
    @Latitude     DECIMAL(9,6)  = NULL,
    @Longitude    DECIMAL(9,6)  = NULL,
    @IsDefault    BIT           = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

            IF @IsDefault = 1
                UPDATE [dbo].[UserAddresses]
                SET    [IsDefault] = 0, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UserId
                WHERE  [UserId] = @UserId AND [IsDeleted] = 0;

            INSERT INTO [dbo].[UserAddresses]
                ([UserId], [Label], [AddressLine1], [AddressLine2], [City], [State], [PinCode], [Country], [Latitude], [Longitude], [IsDefault], [CreatedBy], [UpdatedBy])
            VALUES
                (@UserId, @Label, @AddressLine1, @AddressLine2, @City, @State, @PinCode, @Country, @Latitude, @Longitude, @IsDefault, @UserId, @UserId);

            DECLARE @NewAddressId INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            [AddressId], [UserId], [Label], [AddressLine1], [AddressLine2],
            [City], [State], [PinCode], [Country], [Latitude], [Longitude], [IsDefault]
        FROM [dbo].[UserAddresses]
        WHERE [AddressId] = @NewAddressId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_Address_Delete]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_Address_Delete]
    @AddressId INT,
    @UserId    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[UserAddresses] WHERE [AddressId] = @AddressId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50015, N'Address not found.', 1;

        UPDATE [dbo].[UserAddresses]
        SET    [IsDeleted] = 1,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [AddressId] = @AddressId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_Address_GetByUser]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_Address_GetByUser]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            [AddressId], [UserId], [Label], [AddressLine1], [AddressLine2],
            [City], [State], [PinCode], [Country], [Latitude], [Longitude], [IsDefault]
        FROM [dbo].[UserAddresses]
        WHERE [UserId]    = @UserId
          AND [IsDeleted] = 0
          AND [IsActive]  = 1
        ORDER BY [IsDefault] DESC, [CreatedAt] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_Address_SetDefault]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_Address_SetDefault]
    @AddressId INT,
    @UserId    INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[UserAddresses] WHERE [AddressId] = @AddressId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50016, N'Address not found.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[UserAddresses]
            SET    [IsDefault] = 0, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UserId
            WHERE  [UserId] = @UserId AND [IsDeleted] = 0;

            UPDATE [dbo].[UserAddresses]
            SET    [IsDefault] = 1, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UserId
            WHERE  [AddressId] = @AddressId;

        COMMIT TRANSACTION;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_Address_Update]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_Address_Update]
    @AddressId    INT,
    @UserId       INT,
    @Label        NVARCHAR(50)  = NULL,
    @AddressLine1 NVARCHAR(300) = NULL,
    @AddressLine2 NVARCHAR(300) = NULL,
    @City         NVARCHAR(100) = NULL,
    @State        NVARCHAR(100) = NULL,
    @PinCode      NVARCHAR(10)  = NULL,
    @Country      NVARCHAR(100) = NULL,
    @Latitude     DECIMAL(9,6)  = NULL,
    @Longitude    DECIMAL(9,6)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[UserAddresses] WHERE [AddressId] = @AddressId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50014, N'Address not found.', 1;

        UPDATE [dbo].[UserAddresses]
        SET
            [Label]        = COALESCE(@Label,        [Label]),
            [AddressLine1] = COALESCE(@AddressLine1, [AddressLine1]),
            [AddressLine2] = COALESCE(@AddressLine2, [AddressLine2]),
            [City]         = COALESCE(@City,         [City]),
            [State]        = COALESCE(@State,        [State]),
            [PinCode]      = COALESCE(@PinCode,      [PinCode]),
            [Country]      = COALESCE(@Country,      [Country]),
            [Latitude]     = COALESCE(@Latitude,     [Latitude]),
            [Longitude]    = COALESCE(@Longitude,    [Longitude]),
            [UpdatedAt]    = GETUTCDATE(),
            [UpdatedBy]    = @UserId
        WHERE [AddressId] = @AddressId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_OTP_Send]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_OTP_Send]
    @UserId    INT,
    @OtpCode   NVARCHAR(10),
    @OtpType   TINYINT,        -- 1=Email, 2=Mobile
    @ExpiresAt DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50004, N'User not found.', 1;

        -- Invalidate any previous active OTPs for this user/type
        UPDATE [dbo].[OtpVerifications]
        SET    [IsDeleted] = 1
        WHERE  [UserId]    = @UserId
          AND  [OtpType]   = @OtpType
          AND  [IsUsed]    = 0
          AND  [IsDeleted] = 0;

        INSERT INTO [dbo].[OtpVerifications]
            ([UserId], [OtpCode], [OtpType], [ExpiresAt])
        VALUES
            (@UserId, @OtpCode, @OtpType, @ExpiresAt);

        SELECT SCOPE_IDENTITY() AS [OtpId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_OTP_Verify]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_OTP_Verify]
    @UserId  INT,
    @OtpCode NVARCHAR(10),
    @OtpType TINYINT        -- 1=Email, 2=Mobile
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @OtpId       INT;
        DECLARE @ExpiresAt   DATETIME2(0);
        DECLARE @IsUsed      BIT;
        DECLARE @AttemptCount TINYINT;

        SELECT
            @OtpId        = [OtpId],
            @ExpiresAt    = [ExpiresAt],
            @IsUsed       = [IsUsed],
            @AttemptCount = [AttemptCount]
        FROM [dbo].[OtpVerifications]
        WHERE [UserId]    = @UserId
          AND [OtpType]   = @OtpType
          AND [OtpCode]   = @OtpCode
          AND [IsDeleted] = 0
        ORDER BY [CreatedAt] DESC;

        IF @OtpId IS NULL
            THROW 50005, N'Invalid OTP code.', 1;

        IF @IsUsed = 1
            THROW 50006, N'OTP has already been used.', 1;

        IF @ExpiresAt < GETUTCDATE()
        BEGIN
            UPDATE [dbo].[OtpVerifications] SET [IsDeleted] = 1 WHERE [OtpId] = @OtpId;
            THROW 50007, N'OTP has expired.', 1;
        END;

        IF @AttemptCount >= 5
        BEGIN
            UPDATE [dbo].[OtpVerifications] SET [IsDeleted] = 1 WHERE [OtpId] = @OtpId;
            THROW 50008, N'Maximum OTP attempts exceeded. Please request a new OTP.', 1;
        END;

        BEGIN TRANSACTION;

            UPDATE [dbo].[OtpVerifications]
            SET    [IsUsed]       = 1,
                   [AttemptCount] = [AttemptCount] + 1
            WHERE  [OtpId] = @OtpId;

            -- Mark user email/mobile as verified
            IF @OtpType = 1
                UPDATE [dbo].[Users] SET [IsEmailVerified] = 1, [UpdatedAt] = GETUTCDATE() WHERE [UserId] = @UserId;
            ELSE IF @OtpType = 2
                UPDATE [dbo].[Users] SET [IsMobileVerified] = 1, [UpdatedAt] = GETUTCDATE() WHERE [UserId] = @UserId;

        COMMIT TRANSACTION;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_RefreshToken_Create]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_RefreshToken_Create]
    @UserId     INT,
    @Token      NVARCHAR(500),
    @ExpiresAt  DATETIME2(0),
    @DeviceInfo NVARCHAR(300) = NULL,
    @IpAddress  NVARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        INSERT INTO [dbo].[RefreshTokens]
            ([UserId], [Token], [ExpiresAt], [DeviceInfo], [IpAddress])
        VALUES
            (@UserId, @Token, @ExpiresAt, @DeviceInfo, @IpAddress);

        SELECT SCOPE_IDENTITY() AS [TokenId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_RefreshToken_Validate]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_RefreshToken_Validate]
    @Token NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @TokenId   INT;
        DECLARE @UserId    INT;
        DECLARE @ExpiresAt DATETIME2(0);
        DECLARE @IsRevoked BIT;

        SELECT
            @TokenId   = rt.[TokenId],
            @UserId    = rt.[UserId],
            @ExpiresAt = rt.[ExpiresAt],
            @IsRevoked = rt.[IsRevoked]
        FROM [dbo].[RefreshTokens] rt
        WHERE rt.[Token] = @Token;

        IF @TokenId IS NULL
            THROW 50010, N'Refresh token not found.', 1;

        IF @IsRevoked = 1
            THROW 50011, N'Refresh token has been revoked.', 1;

        IF @ExpiresAt < GETUTCDATE()
        BEGIN
            UPDATE [dbo].[RefreshTokens] SET [IsRevoked] = 1 WHERE [TokenId] = @TokenId;
            THROW 50012, N'Refresh token has expired.', 1;
        END;

        SELECT
            u.[UserId],
            u.[Email],
            u.[RoleId],
            r.[RoleName],
            u.[IsActive],
            u.[IsApproved],
            u.[IsDeleted]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[UserId] = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_User_ForgotPassword]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_User_ForgotPassword]
    @Email NVARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            u.[UserId],
            u.[Email],
            u.[FirstName],
            u.[IsEmailVerified]
        FROM [dbo].[Users] u
        WHERE u.[Email]     = @Email
          AND u.[IsDeleted] = 0
          AND u.[IsActive]  = 1;

        -- Deliberately returns empty if not found (prevents user-enumeration)

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_User_GetIdByMobile]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_User_GetIdByMobile]
    @Mobile NVARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT [UserId]
        FROM   [dbo].[Users]
        WHERE  [Mobile]     = @Mobile
          AND  [IsDeleted]  = 0
          AND  [IsActive]   = 1;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_User_GetProfile]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_User_GetProfile]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            u.[UserId],
            u.[Email],
            u.[Mobile],
            u.[FirstName],
            u.[LastName],
            u.[ProfileImageUrl],
            u.[RoleId],
            r.[RoleName],
            u.[IsEmailVerified],
            u.[IsMobileVerified],
            u.[IsApproved],
            u.[LoyaltyPoints],
            u.[ReferralCode],
            u.[CreatedAt]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[UserId]    = @UserId
          AND u.[IsDeleted] = 0
          AND u.[IsActive]  = 1;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_User_Login]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_User_Login]
    @Email     NVARCHAR(256),
    @IpAddress NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @UserId INT;
        DECLARE @RoleId INT;

        SELECT @UserId = [UserId], @RoleId = [RoleId]
        FROM   [dbo].[Users]
        WHERE  [Email]     = @Email
          AND  [IsDeleted] = 0
          AND  [IsActive]  = 1;

        IF @UserId IS NULL
            THROW 50003, N'User not found or account is inactive.', 1;

        -- Allow Buyer (2) or Admin (1) through the same login page; Seller has its own dedicated page.
        IF @RoleId NOT IN (1, 2)
            THROW 50004, N'This account is not a buyer or admin account. Please use the appropriate login page.', 1;

        UPDATE [dbo].[Users]
        SET    [LastLoginAt] = GETUTCDATE(),
               [UpdatedAt]   = GETUTCDATE()
        WHERE  [UserId] = @UserId;

        SELECT
            u.[UserId],
            u.[Email],
            u.[PasswordHash],
            u.[FirstName],
            u.[LastName],
            u.[Mobile],
            u.[RoleId],
            r.[RoleName],
            u.[ProfileImageUrl],
            u.[IsEmailVerified],
            u.[IsMobileVerified],
            u.[IsApproved],
            u.[IsActive],
            u.[LoyaltyPoints]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[UserId] = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_User_Logout]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_User_Logout]
    @Token NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[RefreshTokens]
        SET    [IsRevoked] = 1
        WHERE  [Token] = @Token;

        SELECT @@ROWCOUNT AS [RevokedCount];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_User_Register]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_User_Register]
    @Email        NVARCHAR(256),
    @PasswordHash NVARCHAR(500),
    @FirstName    NVARCHAR(100) = NULL,
    @LastName     NVARCHAR(100) = NULL,
    @Mobile       NVARCHAR(15)  = NULL,
    @RoleId       TINYINT       = 2          -- 2=Buyer (default)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [Email] = @Email AND [IsDeleted] = 0)
            THROW 50001, N'Email address is already registered.', 1;

        IF @Mobile IS NOT NULL AND EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [Mobile] = @Mobile AND [IsDeleted] = 0)
            THROW 50002, N'Mobile number is already registered.', 1;

        DECLARE @NewReferralCode NVARCHAR(20) = UPPER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)), N'-', N''), 8));
        DECLARE @IsApproved BIT = CASE WHEN @RoleId IN (2) THEN 1 ELSE 0 END; -- Buyers auto-approved; sellers/admins need approval
        DECLARE @NewUserId INT;

        BEGIN TRANSACTION;

            INSERT INTO [dbo].[Users]
                ([Email], [PasswordHash], [FirstName], [LastName], [Mobile], [RoleId], [IsApproved], [ReferralCode])
            VALUES
                (@Email, @PasswordHash, @FirstName, @LastName, @Mobile, @RoleId, @IsApproved, @NewReferralCode);

            SET @NewUserId = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            u.[UserId],
            u.[Email],
            u.[FirstName],
            u.[LastName],
            u.[Mobile],
            u.[RoleId],
            r.[RoleName],
            u.[IsEmailVerified],
            u.[IsMobileVerified],
            u.[IsApproved],
            u.[ReferralCode],
            u.[CreatedAt]
        FROM [dbo].[Users] u
        INNER JOIN [dbo].[Roles] r ON r.[RoleId] = u.[RoleId]
        WHERE u.[UserId] = @NewUserId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_User_ResetPassword]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_User_ResetPassword]
    @UserId          INT,
    @NewPasswordHash NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50009, N'User not found.', 1;

        UPDATE [dbo].[Users]
        SET    [PasswordHash] = @NewPasswordHash,
               [UpdatedAt]    = GETUTCDATE(),
               [UpdatedBy]    = @UserId
        WHERE  [UserId] = @UserId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Auth_User_UpdateProfile]...';


GO
CREATE PROCEDURE [dbo].[usp_Auth_User_UpdateProfile]
    @UserId          INT,
    @FirstName       NVARCHAR(100) = NULL,
    @LastName        NVARCHAR(100) = NULL,
    @ProfileImageUrl NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50013, N'User not found.', 1;

        UPDATE [dbo].[Users]
        SET
            [FirstName]       = COALESCE(@FirstName,       [FirstName]),
            [LastName]        = COALESCE(@LastName,        [LastName]),
            [ProfileImageUrl] = COALESCE(@ProfileImageUrl, [ProfileImageUrl]),
            [UpdatedAt]       = GETUTCDATE(),
            [UpdatedBy]       = @UserId
        WHERE [UserId] = @UserId;

        EXEC [dbo].[usp_Auth_User_GetProfile] @UserId = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Brand_GetAll]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Brand_GetAll]
    @IsFeaturedOnly BIT = 0,
    @PageNumber     INT = 1,
    @PageSize       INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            [BrandId], [BrandName], [SlugUrl], [LogoUrl], [BannerUrl],
            [TagLine], [IsFeatured], [SortOrder],
            [MetaTitle], [MetaDescription]
        FROM [dbo].[Brands]
        WHERE [IsDeleted] = 0
          AND [IsActive]  = 1
          AND (@IsFeaturedOnly = 0 OR [IsFeatured] = 1)
        ORDER BY [SortOrder] ASC, [BrandName] ASC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Brand_GetById]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Brand_GetById]
    @BrandId  INT  = NULL,
    @SlugUrl  NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            [BrandId], [BrandName], [SlugUrl], [LogoUrl], [BannerUrl],
            [Description], [TagLine], [IsFeatured], [SortOrder],
            [MetaTitle], [MetaDescription], [MetaKeywords]
        FROM [dbo].[Brands]
        WHERE [IsDeleted] = 0
          AND [IsActive]  = 1
          AND ([BrandId]  = @BrandId  OR @BrandId IS NULL)
          AND ([SlugUrl]  = @SlugUrl  OR @SlugUrl IS NULL);

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Brand_Update]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Brand_Update]
    @BrandId         INT,
    @BrandName       NVARCHAR(200) = NULL,
    @SlugUrl         NVARCHAR(300) = NULL,
    @LogoUrl         NVARCHAR(500) = NULL,
    @BannerUrl       NVARCHAR(500) = NULL,
    @Description     NVARCHAR(MAX) = NULL,
    @TagLine         NVARCHAR(300) = NULL,
    @IsFeatured      BIT           = NULL,
    @SortOrder       INT           = NULL,
    @MetaTitle       NVARCHAR(200) = NULL,
    @MetaDescription NVARCHAR(500) = NULL,
    @MetaKeywords    NVARCHAR(500) = NULL,
    @IsActive        BIT           = NULL,
    @UpdatedBy       INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Brands] WHERE [BrandId] = @BrandId AND [IsDeleted] = 0)
            THROW 50021, N'Brand not found.', 1;

        IF @SlugUrl IS NOT NULL AND EXISTS (SELECT 1 FROM [dbo].[Brands] WHERE [SlugUrl] = @SlugUrl AND [BrandId] <> @BrandId AND [IsDeleted] = 0)
            THROW 50022, N'Slug URL is already in use by another brand.', 1;

        UPDATE [dbo].[Brands]
        SET
            [BrandName]       = COALESCE(@BrandName,       [BrandName]),
            [SlugUrl]         = COALESCE(@SlugUrl,         [SlugUrl]),
            [LogoUrl]         = COALESCE(@LogoUrl,         [LogoUrl]),
            [BannerUrl]       = COALESCE(@BannerUrl,       [BannerUrl]),
            [Description]     = COALESCE(@Description,     [Description]),
            [TagLine]         = COALESCE(@TagLine,         [TagLine]),
            [IsFeatured]      = COALESCE(@IsFeatured,      [IsFeatured]),
            [SortOrder]       = COALESCE(@SortOrder,       [SortOrder]),
            [MetaTitle]       = COALESCE(@MetaTitle,       [MetaTitle]),
            [MetaDescription] = COALESCE(@MetaDescription, [MetaDescription]),
            [MetaKeywords]    = COALESCE(@MetaKeywords,    [MetaKeywords]),
            [IsActive]        = COALESCE(@IsActive,        [IsActive]),
            [UpdatedAt]       = GETUTCDATE(),
            [UpdatedBy]       = @UpdatedBy
        WHERE [BrandId] = @BrandId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Category_GetAll]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Category_GetAll]
    @MenuId         INT = NULL,    -- NULL = show all menus, otherwise filter by specific MenuId
    @IsFeaturedOnly BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            c.[CategoryId]     AS [Id],
            c.[MenuId],
            c.[CategoryName]   AS [Name],
            c.[SlugUrl],
            m.[MenuName],
            c.[IconUrl],
            c.[BannerUrl],
            c.[SortOrder],
            c.[IsFeatured],
            c.[MetaTitle],
            c.[MetaDescription]
        FROM [dbo].[Categories] c
        INNER JOIN [dbo].[Menus] m ON m.[MenuId] = c.[MenuId]
        WHERE c.[IsDeleted] = 0
          AND c.[IsActive]  = 1
          AND m.[IsDeleted] = 0
          AND m.[IsActive]  = 1
          AND (@MenuId IS NULL OR c.[MenuId] = @MenuId)
          AND (@IsFeaturedOnly = 0 OR c.[IsFeatured] = 1)
        ORDER BY m.[SortOrder] ASC, m.[MenuName] ASC, c.[SortOrder] ASC, c.[CategoryName] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Pincode_Get]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Pincode_Get]
    @Pincode NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            [Pincode],
            [City],
            [State],
            [EstimatedDays],
            CAST(1 AS BIT) AS [IsDeliverable]
        FROM [dbo].[Pincodes]
        WHERE [Pincode]  = @Pincode
          AND [IsActive] = 1;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Product_Create]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Product_Create]
    @SellerId         INT,
    @BrandId          INT,
    @CategoryId       INT,
    @SubCategoryId    INT,
    @ProductName      NVARCHAR(300),
    @SlugUrl          NVARCHAR(400),
    @ShortDescription NVARCHAR(500) = NULL,
    @LongDescription  NVARCHAR(MAX) = NULL,
    @MRP              DECIMAL(18,2),
    @SellingPrice     DECIMAL(18,2),
    @CostPrice        DECIMAL(18,2) = NULL,
    @GstRate          DECIMAL(5,2)  = 0,
    @Sku              NVARCHAR(100) = NULL,
    @GenderTypeId     TINYINT       = NULL,
    @IsReturnable     BIT           = 1,
    @ReturnWindowDays TINYINT       = 7,
    @IsCODAvailable   BIT           = 1,
    @Tags             NVARCHAR(1000) = NULL,
    @MetaTitle        NVARCHAR(200)  = NULL,
    @MetaDescription  NVARCHAR(500)  = NULL,
    @MetaKeywords     NVARCHAR(500)  = NULL,
    @CreatedBy        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0)
            THROW 50030, N'A product with this slug URL already exists.', 1;

        IF @Sku IS NOT NULL AND EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [Sku] = @Sku AND [IsDeleted] = 0)
            THROW 50031, N'A product with this SKU already exists.', 1;

        IF @SellingPrice > @MRP
            THROW 50032, N'Selling price cannot exceed MRP.', 1;

        -- Verify seller-brand mapping is approved
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[SellerBrandMappings]
            WHERE [SellerId] = @SellerId AND [BrandId] = @BrandId AND [IsApproved] = 1 AND [IsDeleted] = 0
        )
            THROW 50033, N'Seller is not authorised to list products under this brand.', 1;

        INSERT INTO [dbo].[Products]
            ([SellerId], [BrandId], [CategoryId], [SubCategoryId], [ProductName], [SlugUrl],
             [ShortDescription], [LongDescription], [MRP], [SellingPrice], [CostPrice], [GstRate],
             [Sku], [GenderTypeId], [IsReturnable], [ReturnWindowDays], [IsCODAvailable],
             [Tags], [MetaTitle], [MetaDescription], [MetaKeywords],
             [ApprovalStatus], [CreatedBy], [UpdatedBy])
        VALUES
            (@SellerId, @BrandId, @CategoryId, @SubCategoryId, @ProductName, @SlugUrl,
             @ShortDescription, @LongDescription, @MRP, @SellingPrice, @CostPrice, @GstRate,
             @Sku, @GenderTypeId, @IsReturnable, @ReturnWindowDays, @IsCODAvailable,
             @Tags, @MetaTitle, @MetaDescription, @MetaKeywords,
             1, @CreatedBy, @CreatedBy);

        DECLARE @NewProductId INT = SCOPE_IDENTITY();

        SELECT @NewProductId AS [ProductId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Product_GetById]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Product_GetById]
    @ProductId INT  = NULL,
    @SlugUrl   NVARCHAR(400) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            p.[ProductId],
            p.[SellerId],
            p.[BrandId],
            p.[CategoryId],
            p.[SubCategoryId],
            p.[ProductName],
            p.[SlugUrl],
            p.[ShortDescription],
            p.[LongDescription],
            p.[MRP],
            p.[SellingPrice],
            p.[GstRate],
            p.[Sku],
            p.[GenderTypeId],
            p.[IsReturnable],
            p.[ReturnWindowDays],
            p.[IsCODAvailable],
            p.[Tags],
            p.[IsFeatured],
            p.[ApprovalStatus],
            p.[PublishedAt],
            p.[MetaTitle],
            p.[MetaDescription],
            p.[MetaKeywords],

            -- Extended product details (nullable)
            p.[Material],
            p.[CareInstructions],
            p.[FitType],
            p.[CountryOfOrigin],
            p.[WarrantyInfo],
            p.[DeliveryInfo],

            b.[BrandName],
            b.[SlugUrl]    AS [BrandSlug],
            b.[LogoUrl]    AS [BrandLogoUrl],

            c.[CategoryName],
            sc.[SubCategoryName],

            gt.[Name]      AS [GenderType],

            s.[BusinessName] AS [SellerName]

        FROM [dbo].[Products]       p
        INNER JOIN [dbo].[Brands]       b   ON b.[BrandId]       = p.[BrandId]
        INNER JOIN [dbo].[Categories]   c   ON c.[CategoryId]    = p.[CategoryId]
        INNER JOIN [dbo].[SubCategories] sc ON sc.[SubCategoryId] = p.[SubCategoryId]
        INNER JOIN [dbo].[Sellers]      s   ON s.[SellerId]       = p.[SellerId]
        LEFT  JOIN [dbo].[GenderTypes]  gt  ON gt.[GenderTypeId]  = p.[GenderTypeId]

        WHERE p.[IsDeleted] = 0
          AND (p.[ProductId] = @ProductId OR @ProductId IS NULL)
          AND (p.[SlugUrl]   = @SlugUrl   OR @SlugUrl   IS NULL);

        -- Return variants
        SELECT
            [VariantId], [ProductId], [Color], [ColorHexCode], [Size],
            [Material], [Pattern], [FitType], [VariantSku],
            [AdditionalPrice], [StockQuantity], [LowStockThreshold],
            [Weight], [Dimensions], [BarCode], [IsActive]
        FROM [dbo].[ProductVariants]
        WHERE [ProductId] = COALESCE(@ProductId,
            (SELECT [ProductId] FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0))
          AND [IsDeleted] = 0;

        -- Return images
        SELECT [ImageId], [VariantId], [ImageUrl], [AltText], [SortOrder], [IsPrimary]
        FROM [dbo].[ProductImages]
        WHERE [ProductId] = COALESCE(@ProductId,
            (SELECT [ProductId] FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0))
          AND [IsDeleted] = 0
        ORDER BY [SortOrder] ASC;

        -- Return specifications
        SELECT [SpecId], [SpecKey], [SpecValue], [SortOrder]
        FROM [dbo].[ProductSpecifications]
        WHERE [ProductId] = COALESCE(@ProductId,
            (SELECT [ProductId] FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0))
          AND [IsDeleted] = 0
        ORDER BY [SortOrder] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Product_GetFeatured]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Product_GetFeatured]
    @GenderTypeId TINYINT = NULL,
    @Limit        INT = 12
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT TOP (@Limit)
            p.[ProductId], p.[ProductName], p.[SlugUrl],
            p.[MRP], p.[SellingPrice], p.[SortOrder],
            b.[BrandName],
            c.[CategoryName],
            gt.[Name]          AS [GenderType],
            pi_.[ImageUrl]     AS [PrimaryImageUrl]
        FROM [dbo].[Products]       p
        INNER JOIN [dbo].[Brands]       b   ON b.[BrandId]      = p.[BrandId]
        INNER JOIN [dbo].[Categories]   c   ON c.[CategoryId]   = p.[CategoryId]
        LEFT  JOIN [dbo].[GenderTypes]  gt  ON gt.[GenderTypeId] = p.[GenderTypeId]
        LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        WHERE p.[IsDeleted]      = 0
          AND p.[IsActive]       = 1
          AND p.[ApprovalStatus] = 2
          AND p.[IsFeatured]     = 1
          AND (p.[GenderTypeId]  = @GenderTypeId OR @GenderTypeId IS NULL)
        ORDER BY p.[SortOrder] ASC, p.[PublishedAt] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Product_ListByBrand]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Product_ListByBrand]
    @BrandId      INT,
    @CategoryId   INT    = NULL,
    @GenderTypeId TINYINT = NULL,
    @SortBy       NVARCHAR(50) = N'Newest',
    @PageNumber   INT = 1,
    @PageSize     INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            p.[ProductId], p.[ProductName], p.[SlugUrl],
            p.[MRP], p.[SellingPrice], p.[IsFeatured],
            b.[BrandName],
            c.[CategoryName],
            gt.[Name]         AS [GenderType],
            pi_.[ImageUrl]    AS [PrimaryImageUrl],
            ISNULL(pv.[MinStock], 0) AS [MinStock],
            COUNT(*) OVER()   AS [TotalCount]
        FROM [dbo].[Products]       p
        INNER JOIN [dbo].[Brands]       b   ON b.[BrandId]       = p.[BrandId]
        INNER JOIN [dbo].[Categories]   c   ON c.[CategoryId]    = p.[CategoryId]
        LEFT  JOIN [dbo].[GenderTypes]  gt  ON gt.[GenderTypeId] = p.[GenderTypeId]
        LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId]  = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN (
            SELECT [ProductId], MIN([StockQuantity]) AS [MinStock]
            FROM [dbo].[ProductVariants] WHERE [IsDeleted] = 0 AND [IsActive] = 1
            GROUP BY [ProductId]
        ) pv ON pv.[ProductId] = p.[ProductId]
        WHERE p.[IsDeleted]      = 0
          AND p.[IsActive]       = 1
          AND p.[ApprovalStatus] = 2
          AND p.[BrandId]        = @BrandId
          AND (p.[CategoryId]    = @CategoryId   OR @CategoryId   IS NULL)
          AND (p.[GenderTypeId]  = @GenderTypeId OR @GenderTypeId IS NULL)
        ORDER BY
            CASE WHEN @SortBy = N'PriceLow'  THEN p.[SellingPrice] END ASC,
            CASE WHEN @SortBy = N'PriceHigh' THEN p.[SellingPrice] END DESC,
            CASE WHEN @SortBy = N'Newest'    THEN p.[PublishedAt]  END DESC,
            p.[SortOrder] ASC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Product_ListByCategory]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Product_ListByCategory]
    @CategoryId    INT,
    @SubCategoryId INT    = NULL,
    @BrandId       INT    = NULL,
    @GenderTypeId  TINYINT = NULL,
    @MinPrice      DECIMAL(18,2) = NULL,
    @MaxPrice      DECIMAL(18,2) = NULL,
    @SortBy        NVARCHAR(50)  = N'Newest',
    @PageNumber    INT = 1,
    @PageSize      INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            p.[ProductId], p.[ProductName], p.[SlugUrl],
            p.[MRP], p.[SellingPrice], p.[IsFeatured],
            b.[BrandId], b.[BrandName],
            c.[CategoryName],
            sc.[SubCategoryName],
            gt.[Name]           AS [GenderType],
            pi_.[ImageUrl]      AS [PrimaryImageUrl],
            ISNULL(pv.[MinStock], 0) AS [MinStock],
            COUNT(*) OVER()     AS [TotalCount]
        FROM [dbo].[Products]         p
        INNER JOIN [dbo].[Brands]         b   ON b.[BrandId]       = p.[BrandId]
        INNER JOIN [dbo].[Categories]     c   ON c.[CategoryId]    = p.[CategoryId]
        INNER JOIN [dbo].[SubCategories]  sc  ON sc.[SubCategoryId] = p.[SubCategoryId]
        LEFT  JOIN [dbo].[GenderTypes]    gt  ON gt.[GenderTypeId]  = p.[GenderTypeId]
        LEFT  JOIN [dbo].[ProductImages]  pi_ ON pi_.[ProductId]    = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN (
            SELECT [ProductId], MIN([StockQuantity]) AS [MinStock]
            FROM [dbo].[ProductVariants] WHERE [IsDeleted] = 0 AND [IsActive] = 1
            GROUP BY [ProductId]
        ) pv ON pv.[ProductId] = p.[ProductId]
        WHERE p.[IsDeleted]      = 0
          AND p.[IsActive]       = 1
          AND p.[ApprovalStatus] = 2
          AND p.[CategoryId]     = @CategoryId
          AND (p.[SubCategoryId] = @SubCategoryId OR @SubCategoryId IS NULL)
          AND (p.[BrandId]       = @BrandId       OR @BrandId       IS NULL)
          AND (p.[GenderTypeId]  = @GenderTypeId  OR @GenderTypeId  IS NULL)
          AND (p.[SellingPrice]  >= @MinPrice      OR @MinPrice      IS NULL)
          AND (p.[SellingPrice]  <= @MaxPrice      OR @MaxPrice      IS NULL)
        ORDER BY
            CASE WHEN @SortBy = N'PriceLow'  THEN p.[SellingPrice] END ASC,
            CASE WHEN @SortBy = N'PriceHigh' THEN p.[SellingPrice] END DESC,
            CASE WHEN @SortBy = N'Newest'    THEN p.[PublishedAt]  END DESC,
            p.[SortOrder] ASC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Product_Search]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Product_Search]
    @SearchTerm    NVARCHAR(500),
    @CategoryId    INT    = NULL,
    @SubCategoryId INT    = NULL,
    @MenuId        INT    = NULL,
    @BrandId       INT    = NULL,
    @GenderTypeId  TINYINT = NULL,
    @MinPrice      DECIMAL(18,2) = NULL,
    @MaxPrice      DECIMAL(18,2) = NULL,
    @SortBy        NVARCHAR(50)  = N'Relevance',  -- Relevance | PriceLow | PriceHigh | Newest
    @PageNumber    INT  = 1,
    @PageSize      INT  = 20,
    @CallerUserId  INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;
        DECLARE @SearchPattern NVARCHAR(502) = CASE WHEN @SearchTerm <> N'' THEN N'%' + @SearchTerm + N'%' ELSE N'%' END;

        -- Log search for analytics
        IF @SearchTerm <> N''
            INSERT INTO [dbo].[SearchLogs] ([UserId], [SearchTerm], [ResultCount], [SearchedAt])
            VALUES (@CallerUserId, @SearchTerm, 0, GETUTCDATE());

        DECLARE @SearchLogId BIGINT = SCOPE_IDENTITY();

        -- LIKE-based search (no full-text index required)
        SELECT
            p.[ProductId]           AS [Id],
            p.[ProductName]         AS [Name],
            p.[SlugUrl],
            p.[CategoryId],
            p.[SubCategoryId],
            p.[SellerId],
            p.[MRP],
            p.[SellingPrice],
            CAST(CASE WHEN p.[MRP] > 0 THEN (p.[MRP] - p.[SellingPrice]) * 100.0 / p.[MRP] ELSE 0 END AS DECIMAL(5,1)) AS [DiscountPct],
            p.[GstRate],
            b.[BrandName],
            c.[CategoryName],
            sc.[SubCategoryName],
            pi_.[ImageUrl]           AS [PrimaryImage],
            ISNULL(pv.[MinStock], 0) AS [MinStock],
            COUNT(*) OVER()          AS [TotalCount]
        FROM [dbo].[Products]       p
        INNER JOIN [dbo].[Brands]         b   ON b.[BrandId]       = p.[BrandId]
        INNER JOIN [dbo].[Categories]     c   ON c.[CategoryId]    = p.[CategoryId]
        LEFT  JOIN [dbo].[SubCategories]  sc  ON sc.[SubCategoryId] = p.[SubCategoryId]
        LEFT  JOIN [dbo].[ProductImages]  pi_ ON pi_.[ProductId]   = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN (
            SELECT [ProductId], MIN([StockQuantity]) AS [MinStock]
            FROM [dbo].[ProductVariants] WHERE [IsDeleted] = 0 AND [IsActive] = 1
            GROUP BY [ProductId]
        ) pv ON pv.[ProductId] = p.[ProductId]
        WHERE p.[IsDeleted]      = 0
          AND p.[IsActive]       = 1
          AND p.[ApprovalStatus] = 2
          AND (p.[CategoryId]    = @CategoryId    OR @CategoryId    IS NULL)
          AND (p.[SubCategoryId] = @SubCategoryId OR @SubCategoryId IS NULL)
          AND (c.[MenuId]        = @MenuId        OR @MenuId        IS NULL)
          AND (p.[BrandId]       = @BrandId      OR @BrandId      IS NULL)
          AND (p.[GenderTypeId]  = @GenderTypeId OR @GenderTypeId IS NULL)
          AND (p.[SellingPrice]  >= @MinPrice     OR @MinPrice     IS NULL)
          AND (p.[SellingPrice]  <= @MaxPrice     OR @MaxPrice     IS NULL)
          AND (p.[ProductName] LIKE @SearchPattern OR p.[ShortDescription] LIKE @SearchPattern OR p.[Tags] LIKE @SearchPattern OR @SearchTerm = N'')
        ORDER BY
            CASE WHEN @SortBy = N'PriceLow'  THEN p.[SellingPrice] END ASC,
            CASE WHEN @SortBy = N'PriceHigh' THEN p.[SellingPrice] END DESC,
            CASE WHEN @SortBy = N'Newest'    THEN p.[PublishedAt]  END DESC,
            p.[ProductName] ASC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

        -- Update result count in search log
        IF @SearchLogId > 0
            UPDATE [dbo].[SearchLogs] SET [ResultCount] = @@ROWCOUNT WHERE [SearchId] = @SearchLogId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Product_Update]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Product_Update]
    @ProductId          INT,
    @ProductName        NVARCHAR(200),
    @ShortDescription   NVARCHAR(500)  = NULL,
    @LongDescription    NVARCHAR(MAX)  = NULL,
    @Sku                NVARCHAR(100),
    @SlugUrl            NVARCHAR(300),
    @MRP                DECIMAL(18,2),
    @SellingPrice       DECIMAL(18,2),
    @CategoryId         INT,
    @SubCategoryId      INT            = NULL,
    @BrandId            INT,
    @GenderTypeId       TINYINT        = NULL,
    @Tags               NVARCHAR(500)  = NULL,
    @IsFeatured         BIT            = 0,
    @Material           NVARCHAR(200)  = NULL,
    @CareInstructions   NVARCHAR(500)  = NULL,
    @FitType            NVARCHAR(50)   = NULL,
    @CountryOfOrigin    NVARCHAR(100)  = NULL,
    @WarrantyInfo       NVARCHAR(500)  = NULL,
    @DeliveryInfo       NVARCHAR(500)  = NULL,
    @UpdatedBy          INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50060, N'Product not found.', 1;

        IF EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [Sku] = @Sku AND [ProductId] <> @ProductId AND [IsDeleted] = 0
        )
            THROW 50061, N'A product with this SKU already exists.', 1;

        IF EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [SlugUrl] = @SlugUrl AND [ProductId] <> @ProductId AND [IsDeleted] = 0
        )
            THROW 50062, N'A product with this slug already exists.', 1;

        UPDATE [dbo].[Products]
        SET    [ProductName]      = @ProductName,
               [ShortDescription] = @ShortDescription,
               [LongDescription]  = @LongDescription,
               [Sku]              = @Sku,
               [SlugUrl]          = @SlugUrl,
               [MRP]              = @MRP,
               [SellingPrice]     = @SellingPrice,
               [CategoryId]       = @CategoryId,
               [SubCategoryId]    = @SubCategoryId,
               [BrandId]          = @BrandId,
               [GenderTypeId]     = @GenderTypeId,
               [Tags]             = @Tags,
               [IsFeatured]       = @IsFeatured,
               [Material]         = COALESCE(@Material,         [Material]),
               [CareInstructions] = COALESCE(@CareInstructions, [CareInstructions]),
               [FitType]          = COALESCE(@FitType,          [FitType]),
               [CountryOfOrigin]  = COALESCE(@CountryOfOrigin,  [CountryOfOrigin]),
               [WarrantyInfo]     = COALESCE(@WarrantyInfo,     [WarrantyInfo]),
               [DeliveryInfo]     = COALESCE(@DeliveryInfo,     [DeliveryInfo]),
               [UpdatedAt]        = GETUTCDATE(),
               [UpdatedBy]        = @UpdatedBy
        WHERE  [ProductId] = @ProductId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_ProductImage_Add]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_ProductImage_Add]
    @ProductId  INT,
    @ImageUrl   NVARCHAR(500),
    @AltText    NVARCHAR(200) = NULL,
    @IsPrimary  BIT           = 0,
    @SortOrder  INT           = 0,
    @CreatedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50080, N'Product not found.', 1;

        BEGIN TRANSACTION;

            IF @IsPrimary = 1
                UPDATE [dbo].[ProductImages]
                SET    [IsPrimary] = 0,
                       [UpdatedAt] = GETUTCDATE(),
                       [UpdatedBy] = @CreatedBy
                WHERE  [ProductId] = @ProductId AND [IsDeleted] = 0;

            INSERT INTO [dbo].[ProductImages]
                ([ProductId], [ImageUrl], [AltText], [IsPrimary], [SortOrder],
                 [CreatedAt], [CreatedBy], [IsDeleted])
            VALUES
                (@ProductId, @ImageUrl, @AltText, @IsPrimary, @SortOrder,
                 GETUTCDATE(), @CreatedBy, 0);

        COMMIT TRANSACTION;

        SELECT SCOPE_IDENTITY() AS [ProductImageId];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_ProductImage_Delete]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_ProductImage_Delete]
    @ImageId    INT,
    @DeletedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[ProductImages]
            WHERE [ImageId] = @ImageId AND [IsDeleted] = 0
        )
            THROW 50085, N'Product image not found.', 1;

        UPDATE [dbo].[ProductImages]
        SET    [IsDeleted]  = 1,
               [UpdatedAt]  = GETUTCDATE(),
               [UpdatedBy]  = @DeletedBy
        WHERE  [ImageId] = @ImageId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_ProductSpec_Upsert]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_ProductSpec_Upsert]
    @ProductId  INT,
    @SpecKey    NVARCHAR(200),
    @SpecValue  NVARCHAR(500),
    @SortOrder  INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[ProductSpecifications]
        SET    [SpecValue] = @SpecValue,
               [SortOrder] = @SortOrder,
               [IsDeleted] = 0
        WHERE  [ProductId] = @ProductId
          AND  [SpecKey]   = @SpecKey;

        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO [dbo].[ProductSpecifications]
                ([ProductId], [SpecKey], [SpecValue], [SortOrder])
            VALUES
                (@ProductId, @SpecKey, @SpecValue, @SortOrder);
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_ProductVariant_GetByProduct]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_ProductVariant_GetByProduct]
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            pv.[VariantId],
            pv.[ProductId],
            pv.[Color],
            pv.[ColorHexCode],
            pv.[Size],
            pv.[Material],
            pv.[Pattern],
            pv.[FitType],
            pv.[VariantSku],
            pv.[AdditionalPrice],
            pv.[StockQuantity],
            pv.[LowStockThreshold],
            pv.[Weight],
            pv.[Dimensions],
            pv.[BarCode],
            pv.[IsActive],
            (p.[SellingPrice] + pv.[AdditionalPrice]) AS [FinalPrice]
        FROM [dbo].[ProductVariants] pv
        INNER JOIN [dbo].[Products] p ON p.[ProductId] = pv.[ProductId]
        WHERE pv.[ProductId] = @ProductId
          AND pv.[IsDeleted] = 0
        ORDER BY pv.[Size] ASC, pv.[Color] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_ProductVariant_Upsert]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_ProductVariant_Upsert]
    @ProductId      INT,
    @VariantId      INT            = NULL,  -- NULL = insert
    @Size           NVARCHAR(50)   = NULL,
    @Color          NVARCHAR(50)   = NULL,
    @Material       NVARCHAR(100)  = NULL,
    @StockQuantity  INT,
    @AdditionalPrice DECIMAL(18,2) = 0.00,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50070, N'Product not found.', 1;

        IF @VariantId IS NULL
        BEGIN
            INSERT INTO [dbo].[ProductVariants]
                ([ProductId], [Size], [Color], [Material], [StockQuantity],
                 [AdditionalPrice], [CreatedAt], [CreatedBy], [IsDeleted])
            VALUES
                (@ProductId, @Size, @Color, @Material, @StockQuantity,
                 @AdditionalPrice, GETUTCDATE(), @UpdatedBy, 0);

            SELECT SCOPE_IDENTITY() AS [VariantId];
        END
        ELSE
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM [dbo].[ProductVariants]
                WHERE [VariantId] = @VariantId AND [ProductId] = @ProductId AND [IsDeleted] = 0
            )
                THROW 50071, N'Variant not found for this product.', 1;

            UPDATE [dbo].[ProductVariants]
            SET    [Size]            = @Size,
                   [Color]           = @Color,
                   [Material]        = @Material,
                   [StockQuantity]   = @StockQuantity,
                   [AdditionalPrice] = @AdditionalPrice,
                   [UpdatedAt]       = GETUTCDATE(),
                   [UpdatedBy]       = @UpdatedBy
            WHERE  [VariantId] = @VariantId;

            SELECT @VariantId AS [VariantId];
        END

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_SubCategory_GetByCategory]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_SubCategory_GetByCategory]
    @CategoryId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            sc.[SubCategoryId]   AS [Id],
            sc.[CategoryId],
            sc.[SubCategoryName] AS [Name],
            sc.[SlugUrl],
            sc.[IconUrl],
            sc.[SortOrder],
            sc.[IsFeatured],
            sc.[MetaTitle],
            sc.[MetaDescription]
        FROM [dbo].[SubCategories] sc
        WHERE sc.[CategoryId] = @CategoryId
          AND sc.[IsDeleted]  = 0
          AND sc.[IsActive]   = 1
        ORDER BY sc.[SortOrder] ASC, sc.[SubCategoryName] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_CMS_Banner_Delete]...';


GO
CREATE PROCEDURE [dbo].[usp_CMS_Banner_Delete]
    @BannerId INT,
    @DeletedBy INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = @BannerId AND [IsDeleted] = 0)
            THROW 50140, N'Banner not found.', 1;

        UPDATE [dbo].[Banners]
        SET    [IsDeleted]  = 1,
               [IsActive]   = 0,
               [UpdatedAt]  = GETUTCDATE(),
               [UpdatedBy]  = @DeletedBy
        WHERE  [BannerId] = @BannerId;

        SELECT @BannerId AS [BannerId];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_CMS_Banner_GetActive]...';


GO
CREATE PROCEDURE [dbo].[usp_CMS_Banner_GetActive]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            b.[BannerId],
            b.[Title],
            b.[SubTitle],
            b.[ImageUrl],
            b.[LinkUrl],
            b.[BannerType],
            b.[SortOrder],
            b.[StartDate],
            b.[EndDate]
        FROM [dbo].[Banners] b
        WHERE b.[IsDeleted] = 0
          AND b.[IsActive]  = 1
          AND (b.[StartDate] IS NULL OR b.[StartDate] <= CAST(GETUTCDATE() AS DATE))
          AND (b.[EndDate]   IS NULL OR b.[EndDate]   >= CAST(GETUTCDATE() AS DATE))
        ORDER BY b.[SortOrder] ASC, b.[CreatedAt] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_CMS_Banner_GetAll]...';


GO
CREATE PROCEDURE [dbo].[usp_CMS_Banner_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            b.[BannerId],
            b.[Title],
            b.[SubTitle],
            b.[ImageUrl],
            b.[MobileImageUrl],
            b.[LinkUrl],
            b.[BannerType]      AS [Section],
            b.[SortOrder],
            b.[IsActive],
            b.[StartDate],
            b.[EndDate],
            b.[CreatedAt],
            b.[UpdatedAt]
        FROM [dbo].[Banners] b
        WHERE b.[IsDeleted] = 0
        ORDER BY b.[BannerType] ASC, b.[SortOrder] ASC, b.[BannerId] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_CMS_Banner_Upsert]...';


GO
CREATE PROCEDURE [dbo].[usp_CMS_Banner_Upsert]
    @BannerId       INT            = NULL,  -- NULL = insert
    @Title          NVARCHAR(200),
    @SubTitle       NVARCHAR(300)  = NULL,
    @ImageUrl       NVARCHAR(500),
    @MobileImageUrl NVARCHAR(500)  = NULL,
    @LinkUrl        NVARCHAR(500)  = NULL,
    @BannerType     TINYINT        = NULL,
    @SortOrder      INT            = 0,
    @IsActive       BIT            = 1,
    @StartDate      DATETIME2(0)   = NULL,
    @EndDate        DATETIME2(0)   = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @BannerId IS NULL
        BEGIN
            INSERT INTO [dbo].[Banners]
                ([Title], [SubTitle], [ImageUrl], [MobileImageUrl], [LinkUrl], [BannerType],
                 [SortOrder], [IsActive], [StartDate], [EndDate],
                 [CreatedAt], [CreatedBy], [IsDeleted])
            VALUES
                (@Title, @SubTitle, @ImageUrl, @MobileImageUrl, @LinkUrl, @BannerType,
                 @SortOrder, @IsActive, @StartDate, @EndDate,
                 GETUTCDATE(), @UpdatedBy, 0);

            SELECT SCOPE_IDENTITY() AS [BannerId];
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM [dbo].[Banners] WHERE [BannerId] = @BannerId AND [IsDeleted] = 0)
                THROW 50140, N'Banner not found.', 1;

            UPDATE [dbo].[Banners]
            SET    [Title]          = @Title,
                   [SubTitle]       = @SubTitle,
                   [ImageUrl]       = @ImageUrl,
                   [MobileImageUrl] = @MobileImageUrl,
                   [LinkUrl]        = @LinkUrl,
                   [BannerType]     = @BannerType,
                   [SortOrder]      = @SortOrder,
                   [IsActive]       = @IsActive,
                   [StartDate]      = @StartDate,
                   [EndDate]        = @EndDate,
                   [UpdatedAt]      = GETUTCDATE(),
                   [UpdatedBy]      = @UpdatedBy
            WHERE  [BannerId] = @BannerId;

            SELECT @BannerId AS [BannerId];
        END

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_CMS_FooterContent_GetAll]...';


GO
CREATE PROCEDURE [dbo].[usp_CMS_FooterContent_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            fc.[FooterId],
            fc.[SectionLabel],
            fc.[LinkLabel],
            fc.[LinkUrl],
            fc.[SortOrder],
            fc.[IsActive]
        FROM [dbo].[FooterContent] fc
        WHERE fc.[IsDeleted] = 0
          AND fc.[IsActive]  = 1
        ORDER BY fc.[SectionLabel] ASC, fc.[SortOrder] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_CMS_HomeSection_GetAll]...';


GO
CREATE PROCEDURE [dbo].[usp_CMS_HomeSection_GetAll]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            hs.[SectionId],
            hs.[SectionName],
            hs.[Title],
            hs.[SubTitle],
            hs.[SectionType],
            hs.[SortOrder],
            hs.[IsActive],
            hs.[FilterJson]
        FROM [dbo].[HomeSections] hs
        WHERE hs.[IsDeleted] = 0
        ORDER BY hs.[SortOrder] ASC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_CMS_HomeSection_Upsert]...';


GO
CREATE PROCEDURE [dbo].[usp_CMS_HomeSection_Upsert]
    @SectionId      INT            = NULL,  -- NULL = insert
    @SectionName    NVARCHAR(100),
    @Title          NVARCHAR(200)  = NULL,
    @SubTitle       NVARCHAR(300)  = NULL,
    @SectionType    NVARCHAR(50),
    @SortOrder      INT            = 0,
    @IsActive       BIT            = 1,
    @FilterJson     NVARCHAR(MAX)  = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @SectionId IS NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM [dbo].[HomeSections] WHERE [SectionName] = @SectionName AND [IsDeleted] = 0)
                THROW 50145, N'A section with this name already exists.', 1;

            INSERT INTO [dbo].[HomeSections]
                ([SectionName], [Title], [SubTitle], [SectionType],
                 [SortOrder], [IsActive], [FilterJson],
                 [CreatedAt], [CreatedBy], [IsDeleted])
            VALUES
                (@SectionName, @Title, @SubTitle, @SectionType,
                 @SortOrder, @IsActive, @FilterJson,
                 GETUTCDATE(), @UpdatedBy, 0);

            SELECT SCOPE_IDENTITY() AS [SectionId];
        END
        ELSE
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM [dbo].[HomeSections] WHERE [SectionId] = @SectionId AND [IsDeleted] = 0)
                THROW 50146, N'Home section not found.', 1;

            UPDATE [dbo].[HomeSections]
            SET    [SectionName]  = @SectionName,
                   [Title]        = @Title,
                   [SubTitle]     = @SubTitle,
                   [SectionType]  = @SectionType,
                   [SortOrder]    = @SortOrder,
                   [IsActive]     = @IsActive,
                   [FilterJson]   = @FilterJson,
                   [UpdatedAt]    = GETUTCDATE(),
                   [UpdatedBy]    = @UpdatedBy
            WHERE  [SectionId] = @SectionId;

            SELECT @SectionId AS [SectionId];
        END

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Cart_Clear]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Cart_Clear]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[Cart]
        SET    [IsDeleted] = 1,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [UserId] = @UserId AND [IsDeleted] = 0;

        SELECT @@ROWCOUNT AS [ClearedCount];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Cart_GetByUser]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Cart_GetByUser]
    @UserId        INT,
    @SavedForLater BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            c.[CartId],
            c.[UserId],
            c.[Quantity],
            c.[SavedForLater],

            p.[ProductId],
            p.[ProductName],
            p.[SlugUrl]        AS [ProductSlug],
            p.[MRP],
            p.[SellingPrice],
            p.[GstRate],
            p.[IsCODAvailable],
            p.[IsReturnable],
            p.[ApprovalStatus] AS [ProductApprovalStatus],
            p.[IsActive]       AS [ProductIsActive],

            pv.[VariantId],
            pv.[Color],
            pv.[ColorHexCode],
            pv.[Size],
            pv.[Material],
            pv.[VariantSku],
            pv.[AdditionalPrice],
            pv.[StockQuantity],
            pv.[LowStockThreshold],
            (p.[SellingPrice] + pv.[AdditionalPrice]) AS [FinalPrice],
            ((p.[SellingPrice] + pv.[AdditionalPrice]) * c.[Quantity]) AS [LineTotal],

            b.[BrandId],
            b.[BrandName],

            pi_.[ImageUrl]     AS [PrimaryImageUrl]

        FROM [dbo].[Cart]              c
        INNER JOIN [dbo].[Products]        p   ON p.[ProductId]  = c.[ProductId]
        INNER JOIN [dbo].[ProductVariants] pv  ON pv.[VariantId] = c.[VariantId]
        INNER JOIN [dbo].[Brands]          b   ON b.[BrandId]    = p.[BrandId]
        LEFT  JOIN [dbo].[ProductImages]   pi_ ON pi_.[ProductId] = p.[ProductId]
                                               AND pi_.[IsPrimary] = 1
                                               AND pi_.[IsDeleted] = 0
        WHERE c.[UserId]       = @UserId
          AND c.[IsDeleted]    = 0
          AND c.[SavedForLater] = @SavedForLater
        ORDER BY c.[AddedAt] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Cart_RemoveItem]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Cart_RemoveItem]
    @CartId INT,
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Cart] WHERE [CartId] = @CartId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50046, N'Cart item not found.', 1;

        UPDATE [dbo].[Cart]
        SET    [IsDeleted] = 1,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [CartId] = @CartId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Cart_UpdateQuantity]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Cart_UpdateQuantity]
    @CartId   INT,
    @UserId   INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Quantity < 1
            THROW 50043, N'Quantity must be at least 1.', 1;

        DECLARE @VariantId INT;
        SELECT @VariantId = [VariantId]
        FROM [dbo].[Cart]
        WHERE [CartId] = @CartId AND [UserId] = @UserId AND [IsDeleted] = 0;

        IF @VariantId IS NULL
            THROW 50044, N'Cart item not found.', 1;

        DECLARE @Stock INT;
        SELECT @Stock = [StockQuantity] FROM [dbo].[ProductVariants] WHERE [VariantId] = @VariantId;

        IF @Stock < @Quantity
            THROW 50045, N'Insufficient stock.', 1;

        UPDATE [dbo].[Cart]
        SET    [Quantity]  = @Quantity,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [CartId] = @CartId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Coupon_Validate]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Coupon_Validate]
    @CouponCode   NVARCHAR(50),
    @UserId       INT,
    @OrderSubTotal DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @OfferId          INT;
        DECLARE @OfferType        TINYINT;
        DECLARE @DiscountValue    DECIMAL(18,2);
        DECLARE @MinOrderValue    DECIMAL(18,2);
        DECLARE @MaxDiscountCap   DECIMAL(18,2);
        DECLARE @UsageLimitPerUser TINYINT;
        DECLARE @CouponId         INT;

        SELECT
            @CouponId          = cp.[CouponId],
            @OfferId           = o.[OfferId],
            @OfferType         = o.[OfferType],
            @DiscountValue     = o.[DiscountValue],
            @MinOrderValue     = o.[MinOrderValue],
            @MaxDiscountCap    = o.[MaxDiscountCap],
            @UsageLimitPerUser = o.[UsageLimitPerUser]
        FROM [dbo].[Coupons] cp
        INNER JOIN [dbo].[Offers] o ON o.[OfferId] = cp.[OfferId]
        WHERE cp.[CouponCode] = @CouponCode
          AND cp.[IsDeleted]  = 0
          AND cp.[IsActive]   = 1
          AND o.[IsDeleted]   = 0
          AND o.[IsActive]    = 1
          AND o.[StartDate]   <= GETUTCDATE()
          AND o.[EndDate]     >= GETUTCDATE()
          AND (o.[UsageLimitTotal] IS NULL OR o.[CurrentUsageCount] < o.[UsageLimitTotal]);

        IF @CouponId IS NULL
            THROW 50063, N'Invalid or expired coupon code.', 1;

        IF @OrderSubTotal < @MinOrderValue
            THROW 50064, N'Order does not meet the minimum value required for this coupon.', 1;

        DECLARE @UserUsage INT = (
            SELECT COUNT(*) FROM [dbo].[Orders]
            WHERE [UserId] = @UserId AND [CouponId] = @CouponId AND [IsDeleted] = 0
        );
        IF @UserUsage >= @UsageLimitPerUser
            THROW 50065, N'You have already used this coupon the maximum number of times.', 1;

        DECLARE @DiscountAmount DECIMAL(18,2) =
            @OrderSubTotal - [dbo].[fn_CalculateDiscountedPrice](@OrderSubTotal, @OfferType, @DiscountValue, @MaxDiscountCap);

        SELECT
            @CouponId       AS [CouponId],
            @CouponCode     AS [CouponCode],
            @DiscountAmount AS [DiscountAmount],
            @OfferType      AS [OfferType],
            1               AS [IsValid];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Order_Cancel]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Order_Cancel]
    @OrderId            INT,
    @UserId             INT,
    @CancellationReason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @CurrentStatus TINYINT;
        SELECT @CurrentStatus = [OrderStatus]
        FROM [dbo].[Orders]
        WHERE [OrderId] = @OrderId AND [UserId] = @UserId AND [IsDeleted] = 0;

        IF @CurrentStatus IS NULL
            THROW 50070, N'Order not found.', 1;

        -- Can only cancel Pending or Confirmed orders
        IF @CurrentStatus NOT IN (1, 2)
            THROW 50071, N'Order cannot be cancelled at this stage.', 1;

        BEGIN TRANSACTION;

            UPDATE [dbo].[Orders]
            SET    [OrderStatus]        = 6,   -- Cancelled
                   [CancelledAt]        = GETUTCDATE(),
                   [CancellationReason] = @CancellationReason,
                   [UpdatedAt]          = GETUTCDATE(),
                   [UpdatedBy]          = @UserId
            WHERE  [OrderId] = @OrderId;

            -- Restore stock
            UPDATE pv
            SET    pv.[StockQuantity] = pv.[StockQuantity] + oi.[Quantity],
                   pv.[UpdatedAt]     = GETUTCDATE(),
                   pv.[UpdatedBy]     = @UserId
            FROM [dbo].[ProductVariants] pv
            INNER JOIN [dbo].[OrderItems] oi ON oi.[VariantId] = pv.[VariantId] AND oi.[OrderId] = @OrderId AND oi.[IsDeleted] = 0;

            -- Notification
            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@UserId,
                 N'Order Cancelled',
                 N'Your order has been cancelled.',
                 1, N'Order', @OrderId, 1);

        COMMIT TRANSACTION;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Order_GetById]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Order_GetById]
    @OrderId INT,
    @UserId  INT = NULL    -- NULL = admin lookup (no user restriction)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            o.[OrderId], o.[OrderNumber], o.[OrderStatus],
            o.[SubTotal], o.[DiscountAmount], o.[CouponDiscount],
            o.[TaxAmount], o.[ShippingCharge], o.[TotalAmount],
            o.[PaymentMode], o.[PaymentStatus], o.[PaymentGatewayRef],
            o.[ExpectedDeliveryDate], o.[DeliveredAt], o.[CancelledAt],
            o.[CancellationReason], o.[CreatedAt] AS [OrderDate],
            -- Address
            ua.[Label]        AS [AddressLabel],
            ua.[AddressLine1], ua.[AddressLine2],
            ua.[City], ua.[State], ua.[PinCode], ua.[Country],
            -- Coupon
            cp.[CouponCode]
        FROM [dbo].[Orders]        o
        INNER JOIN [dbo].[UserAddresses] ua ON ua.[AddressId] = o.[ShippingAddressId]
        LEFT  JOIN [dbo].[Coupons]       cp ON cp.[CouponId]  = o.[CouponId]
        WHERE o.[OrderId]  = @OrderId
          AND o.[IsDeleted] = 0
          AND (@UserId IS NULL OR o.[UserId] = @UserId);

        -- Return order items
        SELECT
            oi.[OrderItemId], oi.[ProductId], oi.[VariantId],
            oi.[ProductName], oi.[VariantSnapshot],
            oi.[Quantity], oi.[UnitPrice], oi.[DiscountAmount],
            oi.[TaxAmount], oi.[TotalPrice],
            oi.[CommissionAmount], oi.[SellerEarning],
            oi.[IsReturned], oi.[ReturnReason],
            b.[BrandName],
            s.[BusinessName] AS [SellerName],
            pi_.[ImageUrl]   AS [ProductImageUrl]
        FROM [dbo].[OrderItems]       oi
        INNER JOIN [dbo].[Brands]         b   ON b.[BrandId]   = oi.[BrandId]
        INNER JOIN [dbo].[Sellers]        s   ON s.[SellerId]  = oi.[SellerId]
        LEFT  JOIN [dbo].[ProductImages]  pi_ ON pi_.[ProductId] = oi.[ProductId]
                                              AND pi_.[IsPrimary] = 1
                                              AND pi_.[IsDeleted] = 0
        WHERE oi.[OrderId]  = @OrderId
          AND oi.[IsDeleted] = 0;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Order_GetByUser]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Order_GetByUser]
    @UserId     INT,
    @OrderStatus TINYINT = NULL,
    @PageNumber INT = 1,
    @PageSize   INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            o.[OrderId],
            o.[OrderNumber],
            o.[OrderStatus],
            o.[TotalAmount],
            o.[PaymentMode],
            o.[PaymentStatus],
            o.[ExpectedDeliveryDate],
            o.[DeliveredAt],
            o.[CreatedAt]     AS [OrderDate],
            COUNT(*) OVER()   AS [TotalCount],
            -- Item count and primary image from first item
            oi.[ItemCount],
            oi.[FirstProductName],
            oi.[FirstProductImage]
        FROM [dbo].[Orders] o
        OUTER APPLY (
            SELECT
                COUNT(*)                       AS [ItemCount],
                MAX(x.[ProductName])           AS [FirstProductName],
                MAX(x.[ImageUrl])              AS [FirstProductImage]
            FROM (
                SELECT TOP 1
                    oi2.[ProductName],
                    pi_.[ImageUrl]
                FROM [dbo].[OrderItems] oi2
                LEFT JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = oi2.[ProductId]
                                                    AND pi_.[IsPrimary] = 1
                                                    AND pi_.[IsDeleted] = 0
                WHERE oi2.[OrderId]  = o.[OrderId]
                  AND oi2.[IsDeleted] = 0
                ORDER BY oi2.[OrderItemId]
            ) x,
            (SELECT COUNT(*) AS [ItemCount]
             FROM [dbo].[OrderItems] WHERE [OrderId] = o.[OrderId] AND [IsDeleted] = 0) cnt
        ) oi
        WHERE o.[UserId]     = @UserId
          AND o.[IsDeleted]  = 0
          AND (@OrderStatus IS NULL OR o.[OrderStatus] = @OrderStatus)
        ORDER BY o.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Order_Place]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Order_Place]
    @UserId            INT,
    @ShippingAddressId INT,
    @PaymentMode       TINYINT,      -- 1=COD, 2=Online, 3=Wallet
    @CouponCode        NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Validate address belongs to user
        IF NOT EXISTS (SELECT 1 FROM [dbo].[UserAddresses] WHERE [AddressId] = @ShippingAddressId AND [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50060, N'Shipping address not found.', 1;

        -- Load active cart into temp table
        CREATE TABLE #CartItems
        (
            CartId     INT, ProductId INT, VariantId INT, SellerId INT, BrandId INT,
            Quantity   INT, UnitPrice DECIMAL(18,2), AdditionalPrice DECIMAL(18,2),
            FinalPrice DECIMAL(18,2), GstRate DECIMAL(5,2),
            ProductName NVARCHAR(300), VariantSku NVARCHAR(150),
            Color NVARCHAR(100), Size NVARCHAR(50), CommissionRate DECIMAL(5,2)
        );

        INSERT INTO #CartItems
        SELECT
            c.[CartId],
            p.[ProductId],
            pv.[VariantId],
            p.[SellerId],
            p.[BrandId],
            c.[Quantity],
            p.[SellingPrice],
            pv.[AdditionalPrice],
            (p.[SellingPrice] + pv.[AdditionalPrice]) AS [FinalPrice],
            p.[GstRate],
            p.[ProductName],
            pv.[VariantSku],
            pv.[Color],
            pv.[Size],
            s.[CommissionRate]
        FROM [dbo].[Cart]              c
        INNER JOIN [dbo].[Products]        p   ON p.[ProductId]  = c.[ProductId]
        INNER JOIN [dbo].[ProductVariants] pv  ON pv.[VariantId] = c.[VariantId]
        INNER JOIN [dbo].[Sellers]         s   ON s.[SellerId]   = p.[SellerId]
        WHERE c.[UserId]       = @UserId
          AND c.[IsDeleted]    = 0
          AND c.[SavedForLater] = 0
          AND p.[IsDeleted]    = 0
          AND p.[IsActive]     = 1
          AND p.[ApprovalStatus] = 2
          AND pv.[IsDeleted]   = 0
          AND pv.[IsActive]    = 1;

        IF NOT EXISTS (SELECT 1 FROM #CartItems)
            THROW 50061, N'Cart is empty or contains no available items.', 1;

        -- Validate stock (row-level lock to prevent overselling)
        IF EXISTS (
            SELECT 1 FROM #CartItems ci
            INNER JOIN [dbo].[ProductVariants] pv WITH (UPDLOCK, ROWLOCK)
                ON pv.[VariantId] = ci.[VariantId]
            WHERE pv.[StockQuantity] < ci.[Quantity]
        )
            THROW 50062, N'One or more items are out of stock.', 1;

        -- Calculate totals
        DECLARE @SubTotal        DECIMAL(18,2) = (SELECT SUM([FinalPrice] * [Quantity]) FROM #CartItems);
        DECLARE @TaxAmount       DECIMAL(18,2) = (SELECT SUM(([FinalPrice] * [Quantity]) * [GstRate] / 100) FROM #CartItems);
        DECLARE @ShippingCharge  DECIMAL(18,2) = CASE WHEN @SubTotal >= 499 THEN 0 ELSE 49 END;
        DECLARE @DiscountAmount  DECIMAL(18,2) = 0;
        DECLARE @CouponDiscount  DECIMAL(18,2) = 0;
        DECLARE @ResolvedCouponId INT          = NULL;

        -- Apply coupon if provided
        IF @CouponCode IS NOT NULL
        BEGIN
            DECLARE @OfferId          INT;
            DECLARE @OfferType        TINYINT;
            DECLARE @DiscountValue    DECIMAL(18,2);
            DECLARE @MinOrderValue    DECIMAL(18,2);
            DECLARE @MaxDiscountCap   DECIMAL(18,2);
            DECLARE @UsageLimitPerUser TINYINT;
            DECLARE @UsageLimitTotal  INT;
            DECLARE @CurrentUsage     INT;

            SELECT
                @ResolvedCouponId  = cp.[CouponId],
                @OfferId           = o.[OfferId],
                @OfferType         = o.[OfferType],
                @DiscountValue     = o.[DiscountValue],
                @MinOrderValue     = o.[MinOrderValue],
                @MaxDiscountCap    = o.[MaxDiscountCap],
                @UsageLimitPerUser = o.[UsageLimitPerUser],
                @UsageLimitTotal   = o.[UsageLimitTotal],
                @CurrentUsage      = o.[CurrentUsageCount]
            FROM [dbo].[Coupons] cp
            INNER JOIN [dbo].[Offers] o ON o.[OfferId] = cp.[OfferId]
            WHERE cp.[CouponCode] = @CouponCode
              AND cp.[IsDeleted]  = 0
              AND cp.[IsActive]   = 1
              AND o.[IsDeleted]   = 0
              AND o.[IsActive]    = 1
              AND o.[StartDate]   <= GETUTCDATE()
              AND o.[EndDate]     >= GETUTCDATE()
              AND (o.[UsageLimitTotal] IS NULL OR o.[CurrentUsageCount] < o.[UsageLimitTotal]);

            IF @ResolvedCouponId IS NULL
                THROW 50063, N'Invalid or expired coupon code.', 1;

            IF @SubTotal < @MinOrderValue
                THROW 50064, N'Order does not meet minimum value for this coupon.', 1;

            -- Check per-user usage
            DECLARE @UserCouponUsage INT = (
                SELECT COUNT(*) FROM [dbo].[Orders]
                WHERE [UserId] = @UserId AND [CouponId] = @ResolvedCouponId AND [IsDeleted] = 0
            );
            IF @UserCouponUsage >= @UsageLimitPerUser
                THROW 50065, N'You have already used this coupon the maximum number of times.', 1;

            -- Calculate coupon discount
            SET @CouponDiscount = [dbo].[fn_CalculateDiscountedPrice](@SubTotal, @OfferType, @DiscountValue, @MaxDiscountCap);
            SET @CouponDiscount = @SubTotal - @CouponDiscount;
        END;

        DECLARE @TotalAmount DECIMAL(18,2) = @SubTotal - @DiscountAmount - @CouponDiscount + @TaxAmount + @ShippingCharge;

        -- Generate order number
        DECLARE @NewOrderId     INT;
        DECLARE @NewOrderNumber NVARCHAR(50);

        BEGIN TRANSACTION;

            -- Insert order
            INSERT INTO [dbo].[Orders]
                ([UserId], [OrderNumber], [OrderStatus], [SubTotal], [DiscountAmount],
                 [CouponId], [CouponDiscount], [TaxAmount], [ShippingCharge], [TotalAmount],
                 [ShippingAddressId], [PaymentMode], [PaymentStatus], [CreatedBy], [UpdatedBy])
            VALUES
                (@UserId, N'PENDING', 1, @SubTotal, @DiscountAmount,
                 @ResolvedCouponId, @CouponDiscount, @TaxAmount, @ShippingCharge, @TotalAmount,
                 @ShippingAddressId, @PaymentMode, 1, @UserId, @UserId);

            SET @NewOrderId = SCOPE_IDENTITY();

            -- Set proper order number (SNS-YYYYMMDD-NNNNN)
            SET @NewOrderNumber = [dbo].[fn_GenerateOrderNumber](@NewOrderId);
            UPDATE [dbo].[Orders] SET [OrderNumber] = @NewOrderNumber WHERE [OrderId] = @NewOrderId;

            -- Insert order items
            INSERT INTO [dbo].[OrderItems]
                ([OrderId], [ProductId], [VariantId], [SellerId], [BrandId],
                 [ProductName], [VariantSnapshot], [Quantity], [UnitPrice],
                 [TaxAmount], [TotalPrice],
                 [SellerCommissionRate], [CommissionAmount], [SellerEarning],
                 [CreatedBy], [UpdatedBy])
            SELECT
                @NewOrderId,
                ci.[ProductId],
                ci.[VariantId],
                ci.[SellerId],
                ci.[BrandId],
                ci.[ProductName],
                ci.[VariantSku] + ISNULL(N' | ' + ci.[Color], N'') + ISNULL(N' | ' + ci.[Size], N''),
                ci.[Quantity],
                ci.[FinalPrice],
                (ci.[FinalPrice] * ci.[Quantity]) * ci.[GstRate] / 100,
                ci.[FinalPrice] * ci.[Quantity],
                ci.[CommissionRate],
                ROUND(ci.[FinalPrice] * ci.[Quantity] * ci.[CommissionRate] / 100, 2),
                ROUND(ci.[FinalPrice] * ci.[Quantity] - (ci.[FinalPrice] * ci.[Quantity] * ci.[CommissionRate] / 100), 2),
                @UserId,
                @UserId
            FROM #CartItems ci;

            -- Deduct stock
            UPDATE pv
            SET    pv.[StockQuantity] = pv.[StockQuantity] - ci.[Quantity],
                   pv.[UpdatedAt]     = GETUTCDATE(),
                   pv.[UpdatedBy]     = @UserId
            FROM [dbo].[ProductVariants] pv
            INNER JOIN #CartItems ci ON ci.[VariantId] = pv.[VariantId];

            -- Clear cart
            UPDATE [dbo].[Cart]
            SET    [IsDeleted] = 1, [UpdatedAt] = GETUTCDATE(), [UpdatedBy] = @UserId
            WHERE  [UserId] = @UserId AND [IsDeleted] = 0 AND [SavedForLater] = 0;

            -- Increment coupon usage count
            IF @ResolvedCouponId IS NOT NULL
                UPDATE [dbo].[Offers]
                SET    [CurrentUsageCount] = [CurrentUsageCount] + 1
                WHERE  [OfferId] = @OfferId;

            -- Create in-app notification
            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@UserId,
                 N'Order Placed Successfully',
                 N'Your order ' + @NewOrderNumber + N' has been placed. Total: ₹' + CAST(@TotalAmount AS NVARCHAR(20)),
                 1, N'Order', @NewOrderId, 1);

        COMMIT TRANSACTION;

        DROP TABLE #CartItems;

        SELECT
            o.[OrderId],
            o.[OrderNumber],
            o.[OrderStatus],
            o.[TotalAmount],
            o.[PaymentMode],
            o.[PaymentStatus],
            o.[CreatedAt] AS [OrderDate]
        FROM [dbo].[Orders] o
        WHERE o.[OrderId] = @NewOrderId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF OBJECT_ID('tempdb..#CartItems') IS NOT NULL DROP TABLE #CartItems;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Wishlist_Add]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Wishlist_Add]
    @UserId    INT,
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50050, N'Product not found.', 1;

        IF EXISTS (SELECT 1 FROM [dbo].[Wishlist] WHERE [UserId] = @UserId AND [ProductId] = @ProductId AND [IsDeleted] = 0)
        BEGIN
            SELECT 1 AS [Success], N'Already in wishlist' AS [Message];
            RETURN;
        END;

        INSERT INTO [dbo].[Wishlist]
            ([UserId], [ProductId], [CreatedBy], [UpdatedBy])
        VALUES
            (@UserId, @ProductId, @UserId, @UserId);

        SELECT 1 AS [Success], N'Added to wishlist' AS [Message];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Wishlist_GetByUser]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Wishlist_GetByUser]
    @UserId     INT,
    @PageNumber INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            w.[WishlistId],
            w.[AddedAt],
            p.[ProductId],
            p.[ProductName],
            p.[SlugUrl],
            p.[MRP],
            p.[SellingPrice],
            p.[IsActive]       AS [ProductIsActive],
            b.[BrandName],
            pi_.[ImageUrl]     AS [PrimaryImageUrl],
            ISNULL(pv.[MinStock], 0) AS [MinStock],
            COUNT(*) OVER()    AS [TotalCount]
        FROM [dbo].[Wishlist]          w
        INNER JOIN [dbo].[Products]        p   ON p.[ProductId]  = w.[ProductId] AND p.[IsDeleted]  = 0
        INNER JOIN [dbo].[Brands]          b   ON b.[BrandId]    = p.[BrandId]   AND b.[IsDeleted]  = 0
        LEFT  JOIN [dbo].[ProductImages]   pi_ ON pi_.[ProductId] = p.[ProductId] AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN (
            SELECT [ProductId], MIN([StockQuantity]) AS [MinStock]
            FROM [dbo].[ProductVariants] WHERE [IsDeleted] = 0 AND [IsActive] = 1
            GROUP BY [ProductId]
        ) pv ON pv.[ProductId] = p.[ProductId]
        WHERE w.[UserId]    = @UserId
          AND w.[IsDeleted] = 0
        ORDER BY w.[AddedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Wishlist_Remove]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Wishlist_Remove]
    @UserId    INT,
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[Wishlist]
        SET    [IsDeleted] = 1,
               [UpdatedAt] = GETUTCDATE(),
               [UpdatedBy] = @UserId
        WHERE  [UserId]    = @UserId
          AND  [ProductId] = @ProductId
          AND  [IsDeleted] = 0;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Engagement_ProductViewLog_Add]...';


GO
CREATE PROCEDURE [dbo].[usp_Engagement_ProductViewLog_Add]
    @ProductId  INT,
    @UserId     INT            = NULL,
    @SessionId  NVARCHAR(100),
    @IpAddress  NVARCHAR(50)   = NULL,
    @DeviceType NVARCHAR(50)   = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        INSERT INTO [dbo].[ProductViewLogs]
            ([ProductId], [UserId], [SessionId], [IpAddress], [DeviceType], [ViewedAt])
        VALUES
            (@ProductId, @UserId, @SessionId, @IpAddress, @DeviceType, GETUTCDATE());

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Engagement_RecentlyViewed_Add]...';


GO
CREATE PROCEDURE [dbo].[usp_Engagement_RecentlyViewed_Add]
    @UserId    INT,
    @ProductId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        MERGE [dbo].[RecentlyViewed] AS tgt
        USING (SELECT @UserId AS [UserId], @ProductId AS [ProductId]) AS src
            ON tgt.[UserId] = src.[UserId] AND tgt.[ProductId] = src.[ProductId]
        WHEN MATCHED THEN UPDATE SET
            tgt.[ViewedAt] = GETUTCDATE()
        WHEN NOT MATCHED THEN INSERT
            ([UserId], [ProductId], [ViewedAt])
        VALUES
            (@UserId, @ProductId, GETUTCDATE());

        -- Keep only the latest 20 entries per user
        DELETE FROM [dbo].[RecentlyViewed]
        WHERE [UserId] = @UserId
          AND [ViewId] NOT IN (
              SELECT TOP 20 [ViewId]
              FROM [dbo].[RecentlyViewed]
              WHERE [UserId] = @UserId
              ORDER BY [ViewedAt] DESC
          );

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Engagement_RecentlyViewed_GetByUser]...';


GO
CREATE PROCEDURE [dbo].[usp_Engagement_RecentlyViewed_GetByUser]
    @UserId INT,
    @Top    INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT TOP (@Top)
            p.[ProductId],
            p.[ProductName],
            p.[SlugUrl],
            p.[SellingPrice],
            p.[MRP],
            pi_.[ImageUrl]  AS [PrimaryImageUrl],
            rv.[ViewedAt]
        FROM [dbo].[RecentlyViewed] rv
        INNER JOIN [dbo].[Products]      p   ON p.[ProductId]  = rv.[ProductId]  AND p.[IsDeleted] = 0
        LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = p.[ProductId]
                                             AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        WHERE rv.[UserId] = @UserId
        ORDER BY rv.[ViewedAt] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Engagement_Review_Add]...';


GO
CREATE PROCEDURE [dbo].[usp_Engagement_Review_Add]
    @UserId       INT,
    @ProductId    INT,
    @OrderItemId  INT,
    @Rating       TINYINT,
    @Title        NVARCHAR(200)  = NULL,
    @Body         NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- When OrderItemId is supplied, verify the user actually purchased and received this item.
        -- When NULL, accept the review as-is (open review flow). Reviews remain unapproved until moderation.
        IF @OrderItemId IS NOT NULL
        BEGIN
            IF NOT EXISTS (
                SELECT 1
                FROM [dbo].[OrderItems] oi
                INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
                WHERE oi.[OrderItemId] = @OrderItemId
                  AND o.[UserId]       = @UserId
                  AND oi.[ProductId]   = @ProductId
                  AND o.[OrderStatus]  = 5  -- Delivered
                  AND oi.[IsDeleted]   = 0
                  AND o.[IsDeleted]    = 0
            )
                THROW 50150, N'You can only review products from delivered orders.', 1;

            IF EXISTS (
                SELECT 1 FROM [dbo].[Reviews]
                WHERE [UserId] = @UserId AND [OrderItemId] = @OrderItemId AND [IsDeleted] = 0
            )
                THROW 50151, N'You have already reviewed this item.', 1;
        END
        ELSE
        BEGIN
            -- Open-review flow: one review per (user, product) when no order is attached.
            IF EXISTS (
                SELECT 1 FROM [dbo].[Reviews]
                WHERE [UserId] = @UserId
                  AND [ProductId] = @ProductId
                  AND [OrderItemId] IS NULL
                  AND [IsDeleted] = 0
            )
                THROW 50151, N'You have already reviewed this product.', 1;
        END

        INSERT INTO [dbo].[Reviews]
            ([UserId], [ProductId], [OrderItemId], [Rating], [Title], [Body],
             [IsApproved], [CreatedAt], [CreatedBy], [IsDeleted])
        VALUES
            (@UserId, @ProductId, @OrderItemId, @Rating, @Title, @Body,
             1, GETUTCDATE(), @UserId, 0);

        SELECT SCOPE_IDENTITY() AS [ReviewId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Engagement_Review_Approve]...';


GO
CREATE PROCEDURE [dbo].[usp_Engagement_Review_Approve]
    @ReviewId   INT,
    @UpdatedBy  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Reviews] WHERE [ReviewId] = @ReviewId AND [IsDeleted] = 0)
            THROW 50155, N'Review not found.', 1;

        UPDATE [dbo].[Reviews]
        SET    [IsApproved] = 1,
               [UpdatedAt]  = GETUTCDATE(),
               [UpdatedBy]  = @UpdatedBy
        WHERE  [ReviewId] = @ReviewId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Engagement_Review_GetByProduct]...';


GO
CREATE PROCEDURE [dbo].[usp_Engagement_Review_GetByProduct]
    @ProductId  INT,
    @PageNumber INT = 1,
    @PageSize   INT = 10
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        -- Rating summary
        SELECT
            COUNT(*)                       AS [TotalReviews],
            CAST(AVG(CAST([Rating] AS DECIMAL(3,2))) AS DECIMAL(3,2)) AS [AverageRating],
            SUM(CASE WHEN [Rating] = 5 THEN 1 ELSE 0 END) AS [FiveStar],
            SUM(CASE WHEN [Rating] = 4 THEN 1 ELSE 0 END) AS [FourStar],
            SUM(CASE WHEN [Rating] = 3 THEN 1 ELSE 0 END) AS [ThreeStar],
            SUM(CASE WHEN [Rating] = 2 THEN 1 ELSE 0 END) AS [TwoStar],
            SUM(CASE WHEN [Rating] = 1 THEN 1 ELSE 0 END) AS [OneStar]
        FROM [dbo].[Reviews]
        WHERE [ProductId]  = @ProductId
          AND [IsApproved] = 1
          AND [IsDeleted]  = 0;

        -- Individual reviews (paginated)
        SELECT
            rv.[ReviewId],
            rv.[Rating],
            rv.[Title],
            rv.[Body],
            rv.[HelpfulCount],
            rv.[CreatedAt],
            u.[FirstName],
            u.[LastName],
            u.[ProfileImageUrl],
            COUNT(*) OVER() AS [TotalCount]
        FROM [dbo].[Reviews] rv
        INNER JOIN [dbo].[Users] u ON u.[UserId] = rv.[UserId]
        WHERE rv.[ProductId]  = @ProductId
          AND rv.[IsApproved] = 1
          AND rv.[IsDeleted]  = 0
        ORDER BY rv.[HelpfulCount] DESC, rv.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Engagement_Review_MarkHelpful]...';


GO
CREATE PROCEDURE [dbo].[usp_Engagement_Review_MarkHelpful]
    @ReviewId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[Reviews]
            WHERE [ReviewId] = @ReviewId AND [IsApproved] = 1 AND [IsDeleted] = 0
        )
            THROW 50160, N'Review not found.', 1;

        UPDATE [dbo].[Reviews]
        SET    [HelpfulCount] = [HelpfulCount] + 1,
               [UpdatedAt]    = GETUTCDATE()
        WHERE  [ReviewId] = @ReviewId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Engagement_SearchLog_Add]...';


GO
CREATE PROCEDURE [dbo].[usp_Engagement_SearchLog_Add]
    @SearchTerm   NVARCHAR(500),
    @UserId       INT            = NULL,
    @ResultCount  INT            = 0,
    @ClickedProductId INT        = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        INSERT INTO [dbo].[SearchLogs]
            ([SearchTerm], [UserId], [ResultCount], [ClickedProductId], [SearchedAt])
        VALUES
            (@SearchTerm, @UserId, @ResultCount, @ClickedProductId, GETUTCDATE());

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Notification_GetByUser]...';


GO
CREATE PROCEDURE [dbo].[usp_Notification_GetByUser]
    @UserId     INT,
    @IsRead     BIT = NULL,
    @PageNumber INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            n.[NotificationId],
            n.[Title],
            n.[Body],
            n.[NotificationType],
            n.[EntityId],
            n.[EntityType],
            n.[IsRead],
            n.[ReadAt],
            n.[CreatedAt],
            COUNT(*) OVER()                                     AS [TotalCount],
            SUM(CASE WHEN n.[IsRead] = 0 THEN 1 ELSE 0 END)
                OVER()                                          AS [UnreadCount]
        FROM [dbo].[Notifications] n
        WHERE n.[UserId]    = @UserId
          AND n.[IsDeleted] = 0
          AND (@IsRead IS NULL OR n.[IsRead] = @IsRead)
        ORDER BY n.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Notification_MarkRead]...';


GO
CREATE PROCEDURE [dbo].[usp_Notification_MarkRead]
    @UserId         INT,
    @NotificationId INT = NULL  -- NULL = mark all as read
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        UPDATE [dbo].[Notifications]
        SET    [IsRead]  = 1,
               [ReadAt]  = GETUTCDATE()
        WHERE  [UserId]    = @UserId
          AND  [IsDeleted] = 0
          AND  [IsRead]    = 0
          AND  (@NotificationId IS NULL OR [NotificationId] = @NotificationId);

        SELECT @@ROWCOUNT AS [UpdatedCount];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Notification_Send]...';


GO
CREATE PROCEDURE [dbo].[usp_Notification_Send]
    @UserId           INT,
    @Title            NVARCHAR(200),
    @Body             NVARCHAR(1000),
    @NotificationType TINYINT       = NULL,
    @EntityId         INT           = NULL,
    @EntityType       NVARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        INSERT INTO [dbo].[Notifications]
            ([UserId], [Title], [Body], [NotificationType],
             [EntityId], [EntityType], [IsRead],
             [CreatedAt], [IsDeleted])
        VALUES
            (@UserId, @Title, @Body, @NotificationType,
             @EntityId, @EntityType, 0,
             GETUTCDATE(), 0);

        SELECT SCOPE_IDENTITY() AS [NotificationId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Pricing_Offer_Create]...';


GO
CREATE PROCEDURE [dbo].[usp_Pricing_Offer_Create]
    @OfferName        NVARCHAR(200),
    @OfferType        TINYINT,        -- 1=Flat, 2=Percentage, 3=BOGO
    @DiscountValue    DECIMAL(18,2),
    @MaxDiscountCap   DECIMAL(18,2)   = NULL,
    @MinOrderValue    DECIMAL(18,2)   = 0.00,
    @ApplicableOn     TINYINT         = 4,  -- 1=Product, 2=Category, 3=Brand, 4=All
    @EntityId         INT             = NULL,
    @StartDate        DATE,
    @EndDate          DATE,
    @UsageLimitTotal  INT             = NULL,
    @CreatedBy        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @StartDate > @EndDate
            THROW 50170, N'StartDate must be before EndDate.', 1;

        IF @OfferType NOT IN (1, 2, 3)
            THROW 50171, N'Invalid offer type. Must be 1 (Flat), 2 (Percentage), or 3 (BOGO).', 1;

        INSERT INTO [dbo].[Offers]
            ([OfferName], [OfferType], [DiscountValue], [MaxDiscountCap],
             [MinOrderValue], [ApplicableOn], [EntityId],
             [StartDate], [EndDate], [UsageLimitTotal], [CurrentUsageCount],
             [IsActive], [CreatedAt], [CreatedBy], [IsDeleted])
        VALUES
            (@OfferName, @OfferType, @DiscountValue, @MaxDiscountCap,
             @MinOrderValue, @ApplicableOn, @EntityId,
             @StartDate, @EndDate, @UsageLimitTotal, 0,
             1, GETUTCDATE(), @CreatedBy, 0);

        SELECT SCOPE_IDENTITY() AS [OfferId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Pricing_Offer_GetActive]...';


GO
CREATE PROCEDURE [dbo].[usp_Pricing_Offer_GetActive]
    @ProductId  INT = NULL,
    @CategoryId INT = NULL,
    @BrandId    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Today DATE = CAST(GETUTCDATE() AS DATE);

        SELECT
            o.[OfferId],
            o.[OfferName],
            o.[OfferType],
            o.[DiscountValue],
            o.[MaxDiscountCap],
            o.[MinOrderValue],
            o.[ApplicableOn],
            o.[EntityId],
            o.[StartDate],
            o.[EndDate],
            o.[UsageLimitTotal],
            o.[CurrentUsageCount]
        FROM [dbo].[Offers] o
        WHERE o.[IsDeleted] = 0
          AND o.[IsActive]  = 1
          AND o.[StartDate] <= @Today
          AND o.[EndDate]   >= @Today
          AND (o.[UsageLimitTotal] IS NULL OR o.[CurrentUsageCount] < o.[UsageLimitTotal])
          AND (
              @ProductId  IS NULL
           OR @CategoryId IS NULL
           OR @BrandId    IS NULL
           OR (o.[ApplicableOn] = 1 AND o.[EntityId] = @ProductId)
           OR (o.[ApplicableOn] = 2 AND o.[EntityId] = @CategoryId)
           OR (o.[ApplicableOn] = 3 AND o.[EntityId] = @BrandId)
           OR  o.[ApplicableOn] = 4
          )
        ORDER BY o.[DiscountValue] DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Pricing_OffersMaster_Get]...';


GO
CREATE PROCEDURE [dbo].[usp_Pricing_OffersMaster_Get]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Today DATE = CAST(GETUTCDATE() AS DATE);

        -- Result set #1: storefront coupons (joined with their backing offer)
        SELECT
            c.[CouponCode],
            o.[OfferName],
            o.[OfferType],
            o.[DiscountValue],
            o.[MinOrderValue],
            o.[MaxDiscountCap],
            o.[EndDate]
        FROM [dbo].[Coupons] c
        INNER JOIN [dbo].[Offers] o ON o.[OfferId] = c.[OfferId]
        WHERE c.[IsDeleted] = 0
          AND c.[IsActive]  = 1
          AND o.[IsDeleted] = 0
          AND o.[IsActive]  = 1
          AND o.[StartDate] <= @Today
          AND o.[EndDate]   >= @Today
        ORDER BY o.[DiscountValue] DESC;

        -- Result set #2: payment / bank offers (informational)
        SELECT
            [BankOfferId],
            [Title],
            [Description],
            [MinSpend],
            [MaxDiscount],
            [TermsUrl],
            [SortOrder]
        FROM [dbo].[BankOffers]
        WHERE [IsDeleted] = 0
          AND [IsActive]  = 1
        ORDER BY [SortOrder] ASC, [BankOfferId] ASC;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_Analytics_Aggregate]...';


GO
-- Called by a scheduled job (e.g., SQL Agent) nightly to populate SellerAnalyticsDaily.
CREATE PROCEDURE [dbo].[usp_Seller_Analytics_Aggregate]
    @AggregateDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @AggregateDate = COALESCE(@AggregateDate, CAST(DATEADD(DAY, -1, GETUTCDATE()) AS DATE));

        BEGIN TRANSACTION;

            MERGE [dbo].[SellerAnalyticsDaily] AS tgt
            USING (
                SELECT
                    oi.[SellerId],
                    @AggregateDate                  AS [AnalyticsDate],
                    COUNT(DISTINCT o.[OrderId])     AS [TotalOrders],
                    SUM(oi.[TotalPrice])            AS [TotalRevenue],
                    SUM(oi.[CommissionAmount])      AS [TotalCommission],
                    SUM(oi.[SellerEarning])         AS [TotalEarnings],
                    ISNULL(pv.[TotalViews], 0)      AS [TotalProductViews],
                    ISNULL(pv.[UniqueVisitors], 0)  AS [TotalUniqueVisitors]
                FROM [dbo].[OrderItems] oi
                INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
                LEFT JOIN (
                    SELECT
                        p.[SellerId],
                        COUNT(*)                          AS [TotalViews],
                        COUNT(DISTINCT pvl.[SessionId])   AS [UniqueVisitors]
                    FROM [dbo].[ProductViewLogs] pvl
                    INNER JOIN [dbo].[Products] p ON p.[ProductId] = pvl.[ProductId]
                    WHERE CAST(pvl.[ViewedAt] AS DATE) = @AggregateDate
                    GROUP BY p.[SellerId]
                ) pv ON pv.[SellerId] = oi.[SellerId]
                WHERE oi.[IsDeleted]  = 0
                  AND o.[IsDeleted]   = 0
                  AND o.[OrderStatus] NOT IN (6, 7)
                  AND CAST(o.[CreatedAt] AS DATE) = @AggregateDate
                GROUP BY oi.[SellerId], pv.[TotalViews], pv.[UniqueVisitors]
            ) AS src
            ON tgt.[SellerId] = src.[SellerId] AND tgt.[AnalyticsDate] = src.[AnalyticsDate]
            WHEN MATCHED THEN UPDATE SET
                tgt.[TotalOrders]         = src.[TotalOrders],
                tgt.[TotalRevenue]        = src.[TotalRevenue],
                tgt.[TotalCommission]     = src.[TotalCommission],
                tgt.[TotalEarnings]       = src.[TotalEarnings],
                tgt.[TotalProductViews]   = src.[TotalProductViews],
                tgt.[TotalUniqueVisitors] = src.[TotalUniqueVisitors],
                tgt.[UpdatedAt]           = GETUTCDATE()
            WHEN NOT MATCHED THEN INSERT
                ([SellerId], [AnalyticsDate], [TotalOrders], [TotalRevenue],
                 [TotalCommission], [TotalEarnings], [TotalProductViews], [TotalUniqueVisitors])
            VALUES
                (src.[SellerId], src.[AnalyticsDate], src.[TotalOrders], src.[TotalRevenue],
                 src.[TotalCommission], src.[TotalEarnings], src.[TotalProductViews], src.[TotalUniqueVisitors]);

        COMMIT TRANSACTION;

        SELECT @@ROWCOUNT AS [UpsertedRows];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_Dashboard_GetAnalytics]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_Dashboard_GetAnalytics]
    @SellerId INT,
    @FromDate DATE = NULL,
    @ToDate   DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SET @FromDate = COALESCE(@FromDate, DATEADD(DAY, -29, CAST(GETUTCDATE() AS DATE)));
        SET @ToDate   = COALESCE(@ToDate,   CAST(GETUTCDATE() AS DATE));

        -- Summary
        SELECT
            SUM(sad.[TotalOrders])         AS [TotalOrders],
            SUM(sad.[TotalRevenue])        AS [TotalRevenue],
            SUM(sad.[TotalCommission])     AS [TotalCommission],
            SUM(sad.[TotalEarnings])       AS [TotalEarnings],
            SUM(sad.[TotalProductViews])   AS [TotalProductViews],
            SUM(sad.[TotalUniqueVisitors]) AS [TotalUniqueVisitors]
        FROM [dbo].[SellerAnalyticsDaily] sad
        WHERE sad.[SellerId]    = @SellerId
          AND sad.[AnalyticsDate] BETWEEN @FromDate AND @ToDate
          AND sad.[IsDeleted]   = 0;

        -- Daily breakdown
        SELECT
            sad.[AnalyticsDate],
            sad.[TotalOrders],
            sad.[TotalRevenue],
            sad.[TotalEarnings],
            sad.[TotalProductViews]
        FROM [dbo].[SellerAnalyticsDaily] sad
        WHERE sad.[SellerId]    = @SellerId
          AND sad.[AnalyticsDate] BETWEEN @FromDate AND @ToDate
          AND sad.[IsDeleted]   = 0
        ORDER BY sad.[AnalyticsDate] ASC;

        -- Top products (live query)
        SELECT TOP 5
            p.[ProductId],
            p.[ProductName],
            p.[SlugUrl],
            SUM(oi.[Quantity])    AS [UnitsSold],
            SUM(oi.[TotalPrice])  AS [Revenue]
        FROM [dbo].[OrderItems] oi
        INNER JOIN [dbo].[Products] p ON p.[ProductId] = oi.[ProductId]
        INNER JOIN [dbo].[Orders]   o ON o.[OrderId]   = oi.[OrderId]
        WHERE oi.[SellerId]   = @SellerId
          AND oi.[IsDeleted]  = 0
          AND o.[IsDeleted]   = 0
          AND o.[OrderStatus] NOT IN (6, 7)
          AND CAST(o.[CreatedAt] AS DATE) BETWEEN @FromDate AND @ToDate
        GROUP BY p.[ProductId], p.[ProductName], p.[SlugUrl]
        ORDER BY SUM(oi.[TotalPrice]) DESC;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_GetProfile]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_GetProfile]
    @SellerId INT = NULL,
    @UserId   INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        SELECT
            s.[SellerId],
            s.[UserId],
            s.[BusinessName],
            s.[GstNumber],
            s.[PanNumber],
            s.[BankName],
            s.[BankIfscCode],
            s.[ApprovalStatus],
            s.[CommissionRate],
            s.[IsActive],
            u.[Email],
            u.[FirstName],
            u.[LastName],
            u.[Mobile],
            u.[ProfileImageUrl],
            ua.[AddressLine1],
            ua.[City],
            ua.[State],
            ua.[PinCode]
        FROM [dbo].[Sellers]       s
        INNER JOIN [dbo].[Users]         u  ON u.[UserId]    = s.[UserId]
        LEFT  JOIN [dbo].[UserAddresses] ua ON ua.[AddressId] = s.[BusinessAddressId]
        WHERE s.[IsDeleted] = 0
          AND (s.[SellerId] = @SellerId OR @SellerId IS NULL)
          AND (s.[UserId]   = @UserId   OR @UserId   IS NULL);

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_Order_Cancel]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_Order_Cancel]
    @OrderId            INT,
    @SellerId           INT,
    @CancellationReason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Verify the seller owns at least one item in this order
        IF NOT EXISTS (
            SELECT 1
            FROM [dbo].[OrderItems] oi
            INNER JOIN [dbo].[ProductVariants] pv ON pv.[VariantId] = oi.[VariantId]
            INNER JOIN [dbo].[Products] p         ON p.[ProductId]  = pv.[ProductId]
            WHERE oi.[OrderId] = @OrderId
              AND p.[SellerId] = @SellerId
              AND oi.[IsDeleted] = 0
        )
            THROW 50090, N'Order not found or you do not have permission to cancel it.', 1;

        DECLARE @CurrentStatus  TINYINT;
        DECLARE @BuyerUserId    INT;
        DECLARE @PaymentMode    TINYINT;
        DECLARE @TotalAmount    DECIMAL(18,2);
        DECLARE @OrderNumber    NVARCHAR(50);

        SELECT
            @CurrentStatus = [OrderStatus],
            @BuyerUserId   = [UserId],
            @PaymentMode   = [PaymentMode],
            @TotalAmount   = [TotalAmount],
            @OrderNumber   = [OrderNumber]
        FROM [dbo].[Orders]
        WHERE [OrderId] = @OrderId AND [IsDeleted] = 0;

        IF @CurrentStatus IS NULL
            THROW 50091, N'Order not found.', 1;

        -- Seller can cancel Pending (1), Confirmed (2), or Processing (3) orders
        IF @CurrentStatus NOT IN (1, 2, 3)
            THROW 50092, N'Order cannot be cancelled at this stage.', 1;

        BEGIN TRANSACTION;

            -- Cancel the order
            UPDATE [dbo].[Orders]
            SET    [OrderStatus]        = 6,
                   [CancelledAt]        = GETUTCDATE(),
                   [CancellationReason] = @CancellationReason,
                   [UpdatedAt]          = GETUTCDATE(),
                   [UpdatedBy]          = @SellerId
            WHERE  [OrderId] = @OrderId;

            -- Restore stock
            UPDATE pv
            SET    pv.[StockQuantity] = pv.[StockQuantity] + oi.[Quantity],
                   pv.[UpdatedAt]     = GETUTCDATE(),
                   pv.[UpdatedBy]     = @SellerId
            FROM [dbo].[ProductVariants] pv
            INNER JOIN [dbo].[OrderItems] oi ON oi.[VariantId] = pv.[VariantId]
                AND oi.[OrderId] = @OrderId
                AND oi.[IsDeleted] = 0;

            -- Credit wallet if payment was online (PaymentMode = 2)
            IF @PaymentMode = 2
            BEGIN
                MERGE [dbo].[Wallets] AS target
                USING (SELECT @BuyerUserId AS [UserId]) AS source ON target.[UserId] = source.[UserId]
                WHEN MATCHED THEN
                    UPDATE SET [Balance] = [Balance] + @TotalAmount, [UpdatedAt] = GETUTCDATE()
                WHEN NOT MATCHED THEN
                    INSERT ([UserId], [Balance], [CreatedAt], [UpdatedAt])
                    VALUES (@BuyerUserId, @TotalAmount, GETUTCDATE(), GETUTCDATE());

                DECLARE @WalletId INT;
                SELECT @WalletId = [WalletId] FROM [dbo].[Wallets] WHERE [UserId] = @BuyerUserId;

                INSERT INTO [dbo].[WalletTransactions]
                    ([WalletId], [UserId], [Amount], [TransactionType],
                     [ReferenceType], [ReferenceId], [Description], [CreatedAt])
                VALUES
                    (@WalletId, @BuyerUserId, @TotalAmount, 1,
                     N'OrderRefund', @OrderId,
                     N'Refund for cancelled order #' + @OrderNumber,
                     GETUTCDATE());
            END;

            -- Notify buyer
            INSERT INTO [dbo].[Notifications]
                ([UserId], [Title], [Body], [NotificationType], [EntityType], [EntityId], [Channel])
            VALUES
                (@BuyerUserId,
                 N'Order Cancelled by Seller',
                 CASE WHEN @PaymentMode = 2
                      THEN N'Your order #' + @OrderNumber + N' has been cancelled by the seller. The amount of ₹' + CAST(@TotalAmount AS NVARCHAR(20)) + N' has been refunded to your wallet.'
                      ELSE N'Your order #' + @OrderNumber + N' has been cancelled by the seller.'
                 END,
                 1, N'Order', @OrderId, 1);

        COMMIT TRANSACTION;

        -- Return order details for email
        SELECT
            @BuyerUserId  AS [BuyerUserId],
            @OrderNumber  AS [OrderNumber],
            @TotalAmount  AS [TotalAmount],
            @PaymentMode  AS [PaymentMode];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_Order_GetAll]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_Order_GetAll]
    @SellerId    INT,
    @OrderStatus TINYINT = NULL,
    @FromDate    DATE    = NULL,
    @ToDate      DATE    = NULL,
    @PageNumber  INT = 1,
    @PageSize    INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            o.[OrderId],
            o.[OrderNumber],
            o.[OrderStatus],
            o.[TotalAmount],
            o.[PaymentMode],
            o.[PaymentStatus],
            o.[CreatedAt]    AS [OrderDate],
            u.[FirstName],
            u.[LastName],
            u.[Email],
            oi.[OrderItemId],
            oi.[ProductName],
            oi.[VariantSnapshot],
            oi.[Quantity],
            oi.[TotalPrice],
            oi.[SellerEarning],
            pi_.[ImageUrl]   AS [ProductImageUrl],
            COUNT(*) OVER()  AS [TotalCount]
        FROM [dbo].[OrderItems]       oi
        INNER JOIN [dbo].[Orders]         o  ON o.[OrderId]  = oi.[OrderId]  AND o.[IsDeleted]  = 0
        INNER JOIN [dbo].[Users]          u  ON u.[UserId]   = o.[UserId]
        LEFT  JOIN [dbo].[ProductImages]  pi_ ON pi_.[ProductId] = oi.[ProductId]
                                              AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        WHERE oi.[SellerId]  = @SellerId
          AND oi.[IsDeleted] = 0
          AND (@OrderStatus IS NULL OR o.[OrderStatus] = @OrderStatus)
          AND (@FromDate     IS NULL OR CAST(o.[CreatedAt] AS DATE) >= @FromDate)
          AND (@ToDate       IS NULL OR CAST(o.[CreatedAt] AS DATE) <= @ToDate)
        ORDER BY o.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_Order_UpdateStatus]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_Order_UpdateStatus]
    @OrderId     INT,
    @SellerId    INT,
    @NewStatus   TINYINT,   -- 3=Processing, 4=Shipped, 5=Delivered
    @UpdatedBy   INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Validate the order contains items from this seller
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[OrderItems] oi
            INNER JOIN [dbo].[Orders] o ON o.[OrderId] = oi.[OrderId]
            WHERE oi.[OrderId] = @OrderId AND oi.[SellerId] = @SellerId
              AND oi.[IsDeleted] = 0 AND o.[IsDeleted] = 0
        )
            THROW 50090, N'Order not found or does not belong to this seller.', 1;

        -- Sellers can only move status forward (no cancellation via this SP)
        IF @NewStatus NOT IN (3, 4, 5)
            THROW 50091, N'Invalid status transition. Sellers may set Processing, Shipped, or Delivered.', 1;

        DECLARE @DeliveredAt DATETIME2(0) = CASE WHEN @NewStatus = 5 THEN GETUTCDATE() ELSE NULL END;

        UPDATE [dbo].[Orders]
        SET    [OrderStatus]  = @NewStatus,
               [DeliveredAt] = COALESCE(@DeliveredAt, [DeliveredAt]),
               [UpdatedAt]   = GETUTCDATE(),
               [UpdatedBy]   = @UpdatedBy
        WHERE  [OrderId] = @OrderId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_Product_Create]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_Product_Create]
    @SellerId           INT,
    @BrandId            INT            = 1,
    @CategoryId         INT,
    @SubCategoryId      INT            = NULL,
    @GenderTypeId       TINYINT        = NULL,
    @ProductName        NVARCHAR(200),
    @ShortDescription   NVARCHAR(500)  = NULL,
    @LongDescription    NVARCHAR(MAX)  = NULL,
    @Sku                NVARCHAR(100),
    @SlugUrl            NVARCHAR(300),
    @MRP                DECIMAL(18,2),
    @SellingPrice       DECIMAL(18,2),
    @Tags               NVARCHAR(500)  = NULL,
    @Material           NVARCHAR(200)  = NULL,
    @CareInstructions   NVARCHAR(500)  = NULL,
    @FitType            NVARCHAR(50)   = NULL,
    @CountryOfOrigin    NVARCHAR(100)  = NULL,
    @WarrantyInfo       NVARCHAR(500)  = NULL,
    @DeliveryInfo       NVARCHAR(500)  = NULL,
    @CreatedBy          INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
            THROW 50100, N'Seller not found.', 1;

        IF EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [Sku] = @Sku AND [IsDeleted] = 0)
            THROW 50101, N'A product with this SKU already exists.', 1;

        IF EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0)
            THROW 50102, N'A product with this slug already exists.', 1;

        INSERT INTO [dbo].[Products]
            ([SellerId], [BrandId], [CategoryId], [SubCategoryId], [GenderTypeId],
             [ProductName], [ShortDescription], [LongDescription], [Sku], [SlugUrl],
             [MRP], [SellingPrice], [Tags], [ApprovalStatus],
             [Material], [CareInstructions], [FitType], [CountryOfOrigin], [WarrantyInfo], [DeliveryInfo],
             [CreatedAt], [CreatedBy], [IsDeleted])
        VALUES
            (@SellerId, @BrandId, @CategoryId, @SubCategoryId, @GenderTypeId,
             @ProductName, @ShortDescription, @LongDescription, @Sku, @SlugUrl,
             @MRP, @SellingPrice, @Tags, 2,  -- ApprovalStatus=2 (Approved) — visible to buyers immediately
             @Material, @CareInstructions, @FitType, @CountryOfOrigin, @WarrantyInfo, @DeliveryInfo,
             GETUTCDATE(), @CreatedBy, 0);

        SELECT SCOPE_IDENTITY() AS [ProductId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_Product_GetAll]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_Product_GetAll]
    @SellerId        INT,
    @ApprovalStatus  TINYINT = NULL,  -- 1=Pending, 2=Approved, 3=Rejected
    @SearchTerm      NVARCHAR(200) = NULL,
    @PageNumber      INT = 1,
    @PageSize        INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@PageNumber - 1) * @PageSize;

        SELECT
            p.[ProductId]                                                          AS [Id],
            p.[ProductName]                                                        AS [Name],
            p.[MRP],
            p.[SellingPrice],
            CASE WHEN p.[MRP] > 0
                 THEN ROUND((p.[MRP] - p.[SellingPrice]) * 100.0 / p.[MRP], 0)
                 ELSE 0 END                                                        AS [DiscountPct],
            ISNULL(SUM(pv.[StockQuantity]), 0)                                     AS [StockQuantity],
            ISNULL(MIN(pv.[LowStockThreshold]), 0)                                 AS [LowStockThreshold],
            pi_.[ImageUrl]                                                         AS [PrimaryImage],
            CASE WHEN p.[ApprovalStatus] = 2 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS [IsApproved],
            p.[CreatedAt],
            COUNT(*)        OVER()                                                 AS [TotalCount]
        FROM [dbo].[Products]         p
        INNER JOIN [dbo].[Brands]      b   ON b.[BrandId]    = p.[BrandId]
        INNER JOIN [dbo].[Categories]  c   ON c.[CategoryId] = p.[CategoryId]
        LEFT  JOIN [dbo].[ProductImages] pi_ ON pi_.[ProductId] = p.[ProductId]
                                              AND pi_.[IsPrimary] = 1 AND pi_.[IsDeleted] = 0
        LEFT  JOIN [dbo].[ProductVariants] pv ON pv.[ProductId] = p.[ProductId] AND pv.[IsDeleted] = 0
        WHERE p.[SellerId]  = @SellerId
          AND p.[IsDeleted] = 0
          AND (@ApprovalStatus IS NULL OR p.[ApprovalStatus] = @ApprovalStatus)
          AND (@SearchTerm    IS NULL  OR p.[ProductName] LIKE N'%' + @SearchTerm + N'%'
                                      OR p.[Sku] LIKE N'%' + @SearchTerm + N'%')
        GROUP BY
            p.[ProductId], p.[ProductName],
            p.[MRP], p.[SellingPrice], p.[ApprovalStatus],
            p.[CreatedAt], pi_.[ImageUrl]
        ORDER BY p.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_ProductImage_Add]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_ProductImage_Add]
    @ProductId  INT,
    @ImageUrl   NVARCHAR(500),
    @IsPrimary  BIT = 0,
    @SortOrder  INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50200, N'Product not found.', 1;

        -- Demote any existing primary if this one is being set primary.
        IF @IsPrimary = 1
        BEGIN
            UPDATE [dbo].[ProductImages]
               SET [IsPrimary] = 0,
                   [UpdatedAt] = GETUTCDATE()
             WHERE [ProductId] = @ProductId
               AND [IsPrimary] = 1
               AND [IsDeleted] = 0;
        END;

        INSERT INTO [dbo].[ProductImages]
            ([ProductId], [ImageUrl], [IsPrimary], [SortOrder])
        VALUES
            (@ProductId, @ImageUrl, @IsPrimary, @SortOrder);

        SELECT CAST(SCOPE_IDENTITY() AS INT) AS [ImageId];
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_ProductVariant_Add]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_ProductVariant_Add]
    @ProductId         INT,
    @Color             NVARCHAR(100)  = NULL,
    @Size              NVARCHAR(50)   = NULL,
    @VariantSku        NVARCHAR(150),
    @StockQuantity     INT            = 0,
    @LowStockThreshold INT            = 5,
    @AdditionalPrice   DECIMAL(18,2)  = 0,
    @CreatedBy         INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Products] WHERE [ProductId] = @ProductId AND [IsDeleted] = 0)
            THROW 50080, N'Product not found.', 1;

        INSERT INTO [dbo].[ProductVariants]
            ([ProductId], [Color], [Size], [VariantSku],
             [StockQuantity], [LowStockThreshold], [AdditionalPrice],
             [CreatedAt], [CreatedBy], [IsActive], [IsDeleted])
        VALUES
            (@ProductId, @Color, @Size, @VariantSku,
             @StockQuantity, @LowStockThreshold, @AdditionalPrice,
             GETUTCDATE(), @CreatedBy, 1, 0);

        SELECT SCOPE_IDENTITY() AS [VariantId];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_ProductVariant_DeleteByProduct]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_ProductVariant_DeleteByProduct]
    @ProductId INT,
    @SellerId  INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [ProductId] = @ProductId AND [SellerId] = @SellerId AND [IsDeleted] = 0
        )
            THROW 50110, N'Product not found for this seller.', 1;

        UPDATE [dbo].[ProductVariants]
        SET    [IsDeleted] = 1,
               [IsActive]  = 0,
               [UpdatedAt] = GETUTCDATE()
        WHERE  [ProductId] = @ProductId
          AND  [IsDeleted] = 0;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_Register]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_Register]
    @UserId       INT,
    @BusinessName NVARCHAR(300),
    @GstNumber    NVARCHAR(20)  = NULL,
    @PanNumber    NVARCHAR(20)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId AND [IsDeleted] = 0 AND [IsActive] = 1)
            THROW 50080, N'User not found.', 1;

        IF EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [UserId] = @UserId AND [IsDeleted] = 0)
            THROW 50081, N'Seller account already exists for this user.', 1;

        BEGIN TRANSACTION;

            -- Upgrade user role to Seller
            UPDATE [dbo].[Users]
            SET    [RoleId]    = 3,
                   [IsApproved] = 0,
                   [UpdatedAt] = GETUTCDATE(),
                   [UpdatedBy] = @UserId
            WHERE  [UserId] = @UserId;

            INSERT INTO [dbo].[Sellers]
                ([UserId], [BusinessName], [GstNumber], [PanNumber],
                 [ApprovalStatus], [CreatedBy], [UpdatedBy])
            VALUES
                (@UserId, @BusinessName, @GstNumber, @PanNumber,
                 1, @UserId, @UserId);

            DECLARE @NewSellerId INT = SCOPE_IDENTITY();

        COMMIT TRANSACTION;

        SELECT
            s.[SellerId], s.[UserId], s.[BusinessName], s.[ApprovalStatus],
            s.[GstNumber], s.[PanNumber], s.[CommissionRate]
        FROM [dbo].[Sellers] s
        WHERE s.[SellerId] = @NewSellerId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Seller_UpdateProfile]...';


GO
CREATE PROCEDURE [dbo].[usp_Seller_UpdateProfile]
    @SellerId       INT,
    @BusinessName   NVARCHAR(200),
    @GstNumber      NVARCHAR(20)   = NULL,
    @PanNumber      NVARCHAR(20)   = NULL,
    @BankName       NVARCHAR(100)  = NULL,
    @BankIfscCode   NVARCHAR(20)   = NULL,
    @BankAccountNumber NVARCHAR(50)   = NULL,
    @UpdatedBy      INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM [dbo].[Sellers] WHERE [SellerId] = @SellerId AND [IsDeleted] = 0)
            THROW 50095, N'Seller not found.', 1;

        UPDATE [dbo].[Sellers]
        SET    [BusinessName]  = @BusinessName,
               [GstNumber]     = @GstNumber,
               [PanNumber]     = @PanNumber,
               [BankName]      = @BankName,
               [BankIfscCode]  = @BankIfscCode,
               [BankAccountNumber] = @BankAccountNumber,
               [UpdatedAt]     = GETUTCDATE(),
               [UpdatedBy]     = @UpdatedBy
        WHERE  [SellerId] = @SellerId;

        SELECT 1 AS [Success];

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Wallet_Credit]...';


GO
CREATE PROCEDURE [dbo].[usp_Wallet_Credit]
    @UserId         INT,
    @Amount         DECIMAL(18,2),
    @ReferenceType  NVARCHAR(50)  = NULL,
    @ReferenceId    INT           = NULL,
    @Description    NVARCHAR(300) = N'Wallet credit'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @Amount <= 0
            THROW 50080, N'Credit amount must be greater than zero.', 1;

        BEGIN TRANSACTION;

            -- Upsert wallet row
            MERGE [dbo].[Wallets] AS target
            USING (SELECT @UserId AS [UserId]) AS source ON target.[UserId] = source.[UserId]
            WHEN MATCHED THEN
                UPDATE SET
                    [Balance]   = [Balance] + @Amount,
                    [UpdatedAt] = GETUTCDATE()
            WHEN NOT MATCHED THEN
                INSERT ([UserId], [Balance], [CreatedAt], [UpdatedAt])
                VALUES (@UserId, @Amount, GETUTCDATE(), GETUTCDATE());

            DECLARE @WalletId    INT;
            DECLARE @NewBalance  DECIMAL(18,2);

            SELECT @WalletId = [WalletId], @NewBalance = [Balance]
            FROM [dbo].[Wallets]
            WHERE [UserId] = @UserId;

            -- Record transaction
            INSERT INTO [dbo].[WalletTransactions]
                ([WalletId], [UserId], [Amount], [TransactionType],
                 [ReferenceType], [ReferenceId], [Description], [CreatedAt])
            VALUES
                (@WalletId, @UserId, @Amount, 1,
                 @ReferenceType, @ReferenceId, @Description, GETUTCDATE());

        COMMIT TRANSACTION;

        SELECT @NewBalance AS [NewBalance], @WalletId AS [WalletId];

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Wallet_GetBalance]...';


GO
CREATE PROCEDURE [dbo].[usp_Wallet_GetBalance]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Return existing wallet or default 0 balance if none exists
        SELECT
            ISNULL(w.[WalletId], 0)         AS [WalletId],
            @UserId                          AS [UserId],
            ISNULL(w.[Balance], 0.00)        AS [Balance],
            ISNULL(w.[UpdatedAt], GETUTCDATE()) AS [UpdatedAt]
        FROM (SELECT 1 AS [x]) AS [dummy]
        LEFT JOIN [dbo].[Wallets] w ON w.[UserId] = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Wallet_GetTransactions]...';


GO
CREATE PROCEDURE [dbo].[usp_Wallet_GetTransactions]
    @UserId   INT,
    @Page     INT = 1,
    @PageSize INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        DECLARE @Offset INT = (@Page - 1) * @PageSize;

        SELECT
            wt.[TransactionId],
            wt.[Amount],
            wt.[TransactionType],
            wt.[ReferenceType],
            wt.[ReferenceId],
            wt.[Description],
            wt.[CreatedAt],
            COUNT(*) OVER() AS [TotalCount]
        FROM [dbo].[WalletTransactions] wt
        WHERE wt.[UserId] = @UserId
        ORDER BY wt.[CreatedAt] DESC
        OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Catalog_Brand_Create]...';


GO
CREATE PROCEDURE [dbo].[usp_Catalog_Brand_Create]
    @BrandName       NVARCHAR(200),
    @SlugUrl         NVARCHAR(300),
    @LogoUrl         NVARCHAR(500) = NULL,
    @BannerUrl       NVARCHAR(500) = NULL,
    @Description     NVARCHAR(MAX) = NULL,
    @TagLine         NVARCHAR(300) = NULL,
    @IsFeatured      BIT           = 0,
    @SortOrder       INT           = 0,
    @MetaTitle       NVARCHAR(200) = NULL,
    @MetaDescription NVARCHAR(500) = NULL,
    @MetaKeywords    NVARCHAR(500) = NULL,
    @CreatedBy       INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM [dbo].[Brands] WHERE [SlugUrl] = @SlugUrl AND [IsDeleted] = 0)
            THROW 50020, N'A brand with this slug URL already exists.', 1;

        INSERT INTO [dbo].[Brands]
            ([BrandName], [SlugUrl], [LogoUrl], [BannerUrl], [Description], [TagLine],
             [IsFeatured], [SortOrder], [MetaTitle], [MetaDescription], [MetaKeywords], [CreatedBy], [UpdatedBy])
        VALUES
            (@BrandName, @SlugUrl, @LogoUrl, @BannerUrl, @Description, @TagLine,
             @IsFeatured, @SortOrder, @MetaTitle, @MetaDescription, @MetaKeywords, @CreatedBy, @CreatedBy);

        DECLARE @NewBrandId INT = SCOPE_IDENTITY();

        EXEC [dbo].[usp_Catalog_Brand_GetById] @BrandId = @NewBrandId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
PRINT N'Creating Procedure [dbo].[usp_Commerce_Cart_AddItem]...';


GO
CREATE PROCEDURE [dbo].[usp_Commerce_Cart_AddItem]
    @UserId    INT,
    @ProductId INT,
    @VariantId INT,
    @Quantity  INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Validate product is active and approved
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[Products]
            WHERE [ProductId] = @ProductId AND [IsDeleted] = 0 AND [IsActive] = 1 AND [ApprovalStatus] = 2
        )
            THROW 50040, N'Product is not available.', 1;

        -- Validate variant
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[ProductVariants]
            WHERE [VariantId] = @VariantId AND [ProductId] = @ProductId AND [IsDeleted] = 0 AND [IsActive] = 1
        )
            THROW 50041, N'Product variant is not available.', 1;

        -- Check stock
        DECLARE @Stock INT;
        SELECT @Stock = [StockQuantity] FROM [dbo].[ProductVariants] WHERE [VariantId] = @VariantId;

        IF @Stock < @Quantity
            THROW 50042, N'Insufficient stock.', 1;

        -- Upsert cart: if same user+variant already in cart, update quantity
        IF EXISTS (SELECT 1 FROM [dbo].[Cart] WHERE [UserId] = @UserId AND [VariantId] = @VariantId AND [IsDeleted] = 0)
        BEGIN
            UPDATE [dbo].[Cart]
            SET    [Quantity]    = [Quantity] + @Quantity,
                   [SavedForLater] = 0,
                   [UpdatedAt]  = GETUTCDATE(),
                   [UpdatedBy]  = @UserId
            WHERE  [UserId]    = @UserId
              AND  [VariantId] = @VariantId
              AND  [IsDeleted] = 0;
        END
        ELSE
        BEGIN
            INSERT INTO [dbo].[Cart]
                ([UserId], [ProductId], [VariantId], [Quantity], [CreatedBy], [UpdatedBy])
            VALUES
                (@UserId, @ProductId, @VariantId, @Quantity, @UserId, @UserId);
        END;

        EXEC [dbo].[usp_Commerce_Cart_GetByUser] @UserId = @UserId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO
/*
Post-Deployment Script — runs after every DACPAC publish.
Scripts execute in dependency order; all use MERGE for idempotency.
*/

--:r .\dbo\Data\Seed_Roles.sql
--:r .\dbo\Data\Seed_GenderTypes.sql
--:r .\dbo\Data\Seed_Menus.sql
--:r .\dbo\Data\Seed_Categories.sql
--:r .\dbo\Data\Seed_SubCategories.sql
--:r .\dbo\Data\Seed_AdminUser.sql
--:r .\dbo\Data\Seed_Brands.sql
--:r .\dbo\Data\Seed_DemoSeller.sql
--:r .\dbo\Data\Seed_Products.sql
--:r .\dbo\Data\Seed_Banners.sql
--:r .\dbo\Data\Seed_Stores.sql
GO

GO
DECLARE @VarDecimalSupported AS BIT;

SELECT @VarDecimalSupported = 0;

IF ((ServerProperty(N'EngineEdition') = 3)
    AND (((@@microsoftversion / power(2, 24) = 9)
          AND (@@microsoftversion & 0xffff >= 3024))
         OR ((@@microsoftversion / power(2, 24) = 10)
             AND (@@microsoftversion & 0xffff >= 1600))))
    SELECT @VarDecimalSupported = 1;

IF (@VarDecimalSupported > 0)
    BEGIN
        EXECUTE sp_db_vardecimal_storage_format N'ShopNShop_db', 'ON';
    END


GO
PRINT N'Update complete.';


GO
