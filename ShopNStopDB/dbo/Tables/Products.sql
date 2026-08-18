CREATE TABLE [dbo].[Products]
(
    [ProductId]        INT             NOT NULL  IDENTITY(1,1),
    [SellerId]         INT             NOT NULL,
    [BrandId]          INT             NOT NULL,
    [CategoryId]       INT             NOT NULL,
    [SubCategoryId]    INT             NULL,
    [ProductName]      NVARCHAR(300)   NOT NULL,
    [SlugUrl]          NVARCHAR(400)   NOT NULL,
    [ShortDescription] NVARCHAR(500)   NULL,
    [LongDescription]  NVARCHAR(MAX)   NULL,
    [MRP]              DECIMAL(18,2)   NOT NULL,
    [SellingPrice]     DECIMAL(18,2)   NOT NULL,
    [CostPrice]        DECIMAL(18,2)   NULL,
    [GstRate]          DECIMAL(5,2)    NOT NULL  CONSTRAINT [DF_Products_GstRate]          DEFAULT 0,
    [Sku]              NVARCHAR(100)   NULL,
    [GenderTypeId]     TINYINT         NULL,
    [IsReturnable]     BIT             NOT NULL  CONSTRAINT [DF_Products_IsReturnable]      DEFAULT 1,
    [ReturnWindowDays] TINYINT         NOT NULL  CONSTRAINT [DF_Products_ReturnWindowDays]  DEFAULT 7,
    [IsCODAvailable]   BIT             NOT NULL  CONSTRAINT [DF_Products_IsCODAvailable]    DEFAULT 1,
    [Tags]             NVARCHAR(1000)  NULL,
    [AITagJson]        NVARCHAR(MAX)   NULL,
    [IsFeatured]       BIT             NOT NULL  CONSTRAINT [DF_Products_IsFeatured]        DEFAULT 0,
    [SortOrder]        INT             NOT NULL  CONSTRAINT [DF_Products_SortOrder]         DEFAULT 0,
    [MetaTitle]        NVARCHAR(200)   NULL,
    [MetaDescription]  NVARCHAR(500)   NULL,
    [MetaKeywords]     NVARCHAR(500)   NULL,
    [ApprovalStatus]   TINYINT         NOT NULL  CONSTRAINT [DF_Products_ApprovalStatus]    DEFAULT 1,  -- 1=Pending,2=Approved,3=Rejected
    [ApprovedBy]       INT             NULL,
    [ApprovedAt]       DATETIME2(0)    NULL,
    [PublishedAt]      DATETIME2(0)    NULL,
    [RejectionReason]  NVARCHAR(500)   NULL,

    -- ── Extended product details (additive; nullable; service-layer defaults applied on read) ──
    [Material]         NVARCHAR(200)   NULL,
    [CareInstructions] NVARCHAR(500)   NULL,
    [FitType]          NVARCHAR(50)    NULL,
    [CountryOfOrigin]  NVARCHAR(100)   NULL,
    [WarrantyInfo]     NVARCHAR(500)   NULL,
    [DeliveryInfo]     NVARCHAR(500)   NULL,

    -- Physical dimensions (rendered when SubCategory.RequiresDimensions = 1)
    [LengthCm]         DECIMAL(8,2)    NULL,
    [WidthCm]          DECIMAL(8,2)    NULL,
    [HeightCm]         DECIMAL(8,2)    NULL,
    [WeightGm]         DECIMAL(10,2)   NULL,

    [CreatedAt]        DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Products_CreatedAt]         DEFAULT GETUTCDATE(),
    [UpdatedAt]        DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Products_UpdatedAt]         DEFAULT GETUTCDATE(),
    [CreatedBy]        INT             NULL,
    [UpdatedBy]        INT             NULL,
    [IsActive]         BIT             NOT NULL  CONSTRAINT [DF_Products_IsActive]          DEFAULT 1,
    [IsDeleted]        BIT             NOT NULL  CONSTRAINT [DF_Products_IsDeleted]         DEFAULT 0,

    CONSTRAINT [PK_Products]               PRIMARY KEY CLUSTERED ([ProductId] ASC),
    CONSTRAINT [UQ_Products_SlugUrl]       UNIQUE ([SlugUrl]),
    CONSTRAINT [UQ_Products_Sku]           UNIQUE ([Sku]),
    CONSTRAINT [CK_Products_ApprovalStatus] CHECK ([ApprovalStatus] IN (1, 2, 3)),

    CONSTRAINT [FK_Products_SellerId]      FOREIGN KEY ([SellerId])     REFERENCES [dbo].[Sellers]      ([SellerId]),
    CONSTRAINT [FK_Products_BrandId]       FOREIGN KEY ([BrandId])      REFERENCES [dbo].[Brands]       ([BrandId]),
    CONSTRAINT [FK_Products_CategoryId]    FOREIGN KEY ([CategoryId])   REFERENCES [dbo].[Categories]   ([CategoryId]),
    CONSTRAINT [FK_Products_SubCategoryId] FOREIGN KEY ([SubCategoryId]) REFERENCES [dbo].[SubCategories] ([SubCategoryId]),
    CONSTRAINT [FK_Products_GenderTypeId]  FOREIGN KEY ([GenderTypeId]) REFERENCES [dbo].[GenderTypes]  ([GenderTypeId]),
    CONSTRAINT [FK_Products_ApprovedBy]    FOREIGN KEY ([ApprovedBy])   REFERENCES [dbo].[Users]        ([UserId]),
    CONSTRAINT [FK_Products_CreatedBy]     FOREIGN KEY ([CreatedBy])    REFERENCES [dbo].[Users]        ([UserId]),
    CONSTRAINT [FK_Products_UpdatedBy]     FOREIGN KEY ([UpdatedBy])    REFERENCES [dbo].[Users]        ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Products_SellerId]
    ON [dbo].[Products] ([SellerId] ASC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_Products_BrandId]
    ON [dbo].[Products] ([BrandId] ASC, [ApprovalStatus] ASC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_Products_CategoryId]
    ON [dbo].[Products] ([CategoryId] ASC, [SubCategoryId] ASC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_Products_GenderTypeId]
    ON [dbo].[Products] ([GenderTypeId] ASC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_Products_ApprovalStatus]
    ON [dbo].[Products] ([ApprovalStatus] ASC, [IsActive] ASC)
    WHERE [IsDeleted] = 0;
GO
