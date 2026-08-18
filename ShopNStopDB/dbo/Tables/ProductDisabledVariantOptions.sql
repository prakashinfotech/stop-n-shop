CREATE TABLE [dbo].[ProductDisabledVariantOptions]
(
    [ProductId]    INT             NOT NULL,
    [OptionId]     INT             NOT NULL,

    [CreatedAt]    DATETIME2(0)    NOT NULL  CONSTRAINT [DF_ProductDisabledVariantOptions_CreatedAt] DEFAULT GETUTCDATE(),
    [CreatedBy]    INT             NULL,

    CONSTRAINT [PK_ProductDisabledVariantOptions]            PRIMARY KEY CLUSTERED ([ProductId] ASC, [OptionId] ASC),
    CONSTRAINT [FK_ProductDisabledVariantOptions_Product]    FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products]                  ([ProductId]),
    CONSTRAINT [FK_ProductDisabledVariantOptions_Option]     FOREIGN KEY ([OptionId])  REFERENCES [dbo].[SubCategoryVariantOptions] ([OptionId])
);
GO
