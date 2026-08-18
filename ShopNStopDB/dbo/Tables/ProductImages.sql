CREATE TABLE [dbo].[ProductImages]
(
    [ImageId]   INT            NOT NULL  IDENTITY(1,1),
    [ProductId] INT            NOT NULL,
    [VariantId] INT            NULL,
    [ImageUrl]  NVARCHAR(500)  NOT NULL,
    [AltText]   NVARCHAR(300)  NULL,
    [SortOrder] INT            NOT NULL  CONSTRAINT [DF_ProductImages_SortOrder]  DEFAULT 0,
    [IsPrimary] BIT            NOT NULL  CONSTRAINT [DF_ProductImages_IsPrimary]  DEFAULT 0,
    [ImageSlot] NVARCHAR(20)   NULL,    -- front|back|left|right|top|bottom|detail|single (NULL for legacy rows)

    [CreatedAt] DATETIME2(0)   NOT NULL  CONSTRAINT [DF_ProductImages_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt] DATETIME2(0)   NOT NULL  CONSTRAINT [DF_ProductImages_UpdatedAt]  DEFAULT GETUTCDATE(),
    [CreatedBy] INT            NULL,
    [UpdatedBy] INT            NULL,
    [IsActive]  BIT            NOT NULL  CONSTRAINT [DF_ProductImages_IsActive]   DEFAULT 1,
    [IsDeleted] BIT            NOT NULL  CONSTRAINT [DF_ProductImages_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_ProductImages]             PRIMARY KEY CLUSTERED ([ImageId] ASC),

    CONSTRAINT [FK_ProductImages_ProductId]   FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products]        ([ProductId]),
    CONSTRAINT [FK_ProductImages_VariantId]   FOREIGN KEY ([VariantId]) REFERENCES [dbo].[ProductVariants] ([VariantId]),
    CONSTRAINT [FK_ProductImages_CreatedBy]   FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]           ([UserId]),
    CONSTRAINT [FK_ProductImages_UpdatedBy]   FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]           ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_ProductImages_ProductId]
    ON [dbo].[ProductImages] ([ProductId] ASC, [SortOrder] ASC)
    WHERE [IsDeleted] = 0;
GO
