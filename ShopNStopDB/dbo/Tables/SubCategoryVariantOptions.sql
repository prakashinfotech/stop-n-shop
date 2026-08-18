CREATE TABLE [dbo].[SubCategoryVariantOptions]
(
    [OptionId]        INT             NOT NULL  IDENTITY(1,1),
    [SubCategoryId]   INT             NOT NULL,
    [AttributeId]     INT             NOT NULL,
    [OptionValue]     NVARCHAR(100)   NOT NULL,    -- e.g. 'XL' | 'Red' | 'Cotton'
    [OptionMetadata]  NVARCHAR(200)   NULL,        -- e.g. '#FF0000' for swatches
    [SortOrder]       INT             NOT NULL  CONSTRAINT [DF_SubCategoryVariantOptions_SortOrder]  DEFAULT 0,

    [CreatedAt]       DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SubCategoryVariantOptions_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SubCategoryVariantOptions_UpdatedAt] DEFAULT GETUTCDATE(),
    [CreatedBy]       INT             NULL,
    [UpdatedBy]       INT             NULL,
    [IsActive]        BIT             NOT NULL  CONSTRAINT [DF_SubCategoryVariantOptions_IsActive]  DEFAULT 1,

    CONSTRAINT [PK_SubCategoryVariantOptions]            PRIMARY KEY CLUSTERED ([OptionId] ASC),
    CONSTRAINT [UQ_SubCategoryVariantOptions_Triple]     UNIQUE ([SubCategoryId], [AttributeId], [OptionValue]),

    CONSTRAINT [FK_SubCategoryVariantOptions_SubCategory] FOREIGN KEY ([SubCategoryId]) REFERENCES [dbo].[SubCategories]      ([SubCategoryId]),
    CONSTRAINT [FK_SubCategoryVariantOptions_Attribute]   FOREIGN KEY ([AttributeId])   REFERENCES [dbo].[VariantAttributes]  ([AttributeId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SubCategoryVariantOptions_Lookup]
    ON [dbo].[SubCategoryVariantOptions] ([SubCategoryId] ASC, [AttributeId] ASC, [SortOrder] ASC)
    WHERE [IsActive] = 1;
GO
