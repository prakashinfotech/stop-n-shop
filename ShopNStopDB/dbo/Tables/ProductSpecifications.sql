CREATE TABLE [dbo].[ProductSpecifications]
(
    [SpecId]    INT            NOT NULL  IDENTITY(1,1),
    [ProductId] INT            NOT NULL,
    [SpecKey]   NVARCHAR(200)  NOT NULL,
    [SpecValue] NVARCHAR(500)  NOT NULL,
    [SortOrder] INT            NOT NULL  CONSTRAINT [DF_ProductSpecifications_SortOrder]   DEFAULT 0,

    [CreatedAt] DATETIME2(0)   NOT NULL  CONSTRAINT [DF_ProductSpecifications_CreatedAt]   DEFAULT GETUTCDATE(),
    [IsDeleted] BIT            NOT NULL  CONSTRAINT [DF_ProductSpecifications_IsDeleted]   DEFAULT 0,

    CONSTRAINT [PK_ProductSpecifications]           PRIMARY KEY CLUSTERED ([SpecId] ASC),

    CONSTRAINT [FK_ProductSpecifications_ProductId] FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId])
);
GO

CREATE NONCLUSTERED INDEX [IX_ProductSpecifications_ProductId]
    ON [dbo].[ProductSpecifications] ([ProductId] ASC, [SortOrder] ASC)
    WHERE [IsDeleted] = 0;
GO
