CREATE TABLE [dbo].[ProductSubCategories]
(
    [ProductId]     INT          NOT NULL,
    [SubCategoryId] INT          NOT NULL,
    [CreatedAt]     DATETIME2(0) NOT NULL CONSTRAINT [DF_PSC_CreatedAt] DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_ProductSubCategories]    PRIMARY KEY CLUSTERED ([ProductId] ASC, [SubCategoryId] ASC),
    CONSTRAINT [FK_PSC_Product]             FOREIGN KEY ([ProductId])     REFERENCES [dbo].[Products]      ([ProductId]),
    CONSTRAINT [FK_PSC_SubCategory]         FOREIGN KEY ([SubCategoryId]) REFERENCES [dbo].[SubCategories] ([SubCategoryId])
);
GO

CREATE NONCLUSTERED INDEX [IX_PSC_SubCategoryId]
    ON [dbo].[ProductSubCategories] ([SubCategoryId] ASC) INCLUDE ([ProductId]);
GO
