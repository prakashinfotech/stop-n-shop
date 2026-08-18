CREATE TABLE [dbo].[ReviewImages]
(
    [ReviewImageId] INT            NOT NULL  IDENTITY(1,1),
    [ReviewId]      INT            NOT NULL,
    [ImageUrl]      NVARCHAR(500)  NOT NULL,

    [CreatedAt]     DATETIME2(0)   NOT NULL  CONSTRAINT [DF_ReviewImages_CreatedAt]  DEFAULT GETUTCDATE(),
    [IsDeleted]     BIT            NOT NULL  CONSTRAINT [DF_ReviewImages_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_ReviewImages]            PRIMARY KEY CLUSTERED ([ReviewImageId] ASC),

    CONSTRAINT [FK_ReviewImages_ReviewId]   FOREIGN KEY ([ReviewId]) REFERENCES [dbo].[Reviews] ([ReviewId])
);
GO

CREATE NONCLUSTERED INDEX [IX_ReviewImages_ReviewId]
    ON [dbo].[ReviewImages] ([ReviewId] ASC)
    WHERE [IsDeleted] = 0;
GO
