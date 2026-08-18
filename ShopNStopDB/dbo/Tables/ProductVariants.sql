CREATE TABLE [dbo].[ProductVariants]
(
    [VariantId]          INT             NOT NULL  IDENTITY(1,1),
    [ProductId]          INT             NOT NULL,
    [Color]              NVARCHAR(100)   NULL,
    [ColorHexCode]       NVARCHAR(10)    NULL,
    [Size]               NVARCHAR(50)    NULL,
    [Material]           NVARCHAR(100)   NULL,
    [Pattern]            NVARCHAR(100)   NULL,
    [FitType]            NVARCHAR(100)   NULL,
    [VariantSku]         NVARCHAR(150)   NOT NULL,
    [AdditionalPrice]    DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_ProductVariants_AdditionalPrice]    DEFAULT 0,
    [StockQuantity]      INT             NOT NULL  CONSTRAINT [DF_ProductVariants_StockQuantity]      DEFAULT 0,
    [LowStockThreshold]  INT             NOT NULL  CONSTRAINT [DF_ProductVariants_LowStockThreshold]  DEFAULT 5,
    [Weight]             DECIMAL(10,3)   NULL,
    [Dimensions]         NVARCHAR(100)   NULL,
    [BarCode]            NVARCHAR(100)   NULL,

    [CreatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_ProductVariants_CreatedAt]          DEFAULT GETUTCDATE(),
    [UpdatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_ProductVariants_UpdatedAt]          DEFAULT GETUTCDATE(),
    [CreatedBy]          INT             NULL,
    [UpdatedBy]          INT             NULL,
    [IsActive]           BIT             NOT NULL  CONSTRAINT [DF_ProductVariants_IsActive]           DEFAULT 1,
    [IsDeleted]          BIT             NOT NULL  CONSTRAINT [DF_ProductVariants_IsDeleted]          DEFAULT 0,

    CONSTRAINT [PK_ProductVariants]             PRIMARY KEY CLUSTERED ([VariantId] ASC),
    CONSTRAINT [UQ_ProductVariants_VariantSku]  UNIQUE ([VariantSku]),

    CONSTRAINT [FK_ProductVariants_ProductId]   FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]),
    CONSTRAINT [FK_ProductVariants_CreatedBy]   FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]    ([UserId]),
    CONSTRAINT [FK_ProductVariants_UpdatedBy]   FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]    ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_ProductVariants_ProductId]
    ON [dbo].[ProductVariants] ([ProductId] ASC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_ProductVariants_StockQuantity]
    ON [dbo].[ProductVariants] ([ProductId] ASC, [StockQuantity] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
