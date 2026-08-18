CREATE TABLE [dbo].[RecentlyViewed]
(
    [ViewId]    INT            NOT NULL  IDENTITY(1,1),
    [UserId]    INT            NOT NULL,
    [ProductId] INT            NOT NULL,
    [ViewedAt]  DATETIME2(0)   NOT NULL  CONSTRAINT [DF_RecentlyViewed_ViewedAt]   DEFAULT GETUTCDATE(),

    [CreatedAt] DATETIME2(0)   NOT NULL  CONSTRAINT [DF_RecentlyViewed_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt] DATETIME2(0)   NOT NULL  CONSTRAINT [DF_RecentlyViewed_UpdatedAt]  DEFAULT GETUTCDATE(),
    [IsDeleted] BIT            NOT NULL  CONSTRAINT [DF_RecentlyViewed_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_RecentlyViewed]              PRIMARY KEY CLUSTERED ([ViewId] ASC),
    CONSTRAINT [UQ_RecentlyViewed_UserProduct]  UNIQUE ([UserId], [ProductId]),

    CONSTRAINT [FK_RecentlyViewed_UserId]       FOREIGN KEY ([UserId])    REFERENCES [dbo].[Users]    ([UserId]),
    CONSTRAINT [FK_RecentlyViewed_ProductId]    FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId])
);
GO

CREATE NONCLUSTERED INDEX [IX_RecentlyViewed_UserId]
    ON [dbo].[RecentlyViewed] ([UserId] ASC, [ViewedAt] DESC)
    WHERE [IsDeleted] = 0;
GO
