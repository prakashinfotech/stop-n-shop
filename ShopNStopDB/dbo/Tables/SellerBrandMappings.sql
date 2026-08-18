CREATE TABLE [dbo].[SellerBrandMappings]
(
    [MappingId]  INT            NOT NULL  IDENTITY(1,1),
    [SellerId]   INT            NOT NULL,
    [BrandId]    INT            NOT NULL,
    [ApprovedBy] INT            NULL,
    [ApprovedAt] DATETIME2(0)   NULL,
    [IsApproved] BIT            NOT NULL  CONSTRAINT [DF_SellerBrandMappings_IsApproved]  DEFAULT 0,

    [CreatedAt]  DATETIME2(0)   NOT NULL  CONSTRAINT [DF_SellerBrandMappings_CreatedAt]   DEFAULT GETUTCDATE(),
    [UpdatedAt]  DATETIME2(0)   NOT NULL  CONSTRAINT [DF_SellerBrandMappings_UpdatedAt]   DEFAULT GETUTCDATE(),
    [CreatedBy]  INT            NULL,
    [UpdatedBy]  INT            NULL,
    [IsActive]   BIT            NOT NULL  CONSTRAINT [DF_SellerBrandMappings_IsActive]    DEFAULT 1,
    [IsDeleted]  BIT            NOT NULL  CONSTRAINT [DF_SellerBrandMappings_IsDeleted]   DEFAULT 0,

    CONSTRAINT [PK_SellerBrandMappings]              PRIMARY KEY CLUSTERED ([MappingId] ASC),
    CONSTRAINT [UQ_SellerBrandMappings_SellerBrand]  UNIQUE ([SellerId], [BrandId]),

    CONSTRAINT [FK_SellerBrandMappings_SellerId]     FOREIGN KEY ([SellerId])   REFERENCES [dbo].[Sellers] ([SellerId]),
    CONSTRAINT [FK_SellerBrandMappings_BrandId]      FOREIGN KEY ([BrandId])    REFERENCES [dbo].[Brands]  ([BrandId]),
    CONSTRAINT [FK_SellerBrandMappings_ApprovedBy]   FOREIGN KEY ([ApprovedBy]) REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_SellerBrandMappings_CreatedBy]    FOREIGN KEY ([CreatedBy])  REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_SellerBrandMappings_UpdatedBy]    FOREIGN KEY ([UpdatedBy])  REFERENCES [dbo].[Users]   ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SellerBrandMappings_BrandId]
    ON [dbo].[SellerBrandMappings] ([BrandId] ASC)
    WHERE [IsDeleted] = 0;
GO
