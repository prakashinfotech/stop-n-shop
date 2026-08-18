CREATE TABLE [dbo].[Wishlist]
(
    [WishlistId] INT            NOT NULL  IDENTITY(1,1),
    [UserId]     INT            NOT NULL,
    [ProductId]  INT            NOT NULL,
    [AddedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Wishlist_AddedAt]    DEFAULT GETUTCDATE(),

    [CreatedAt]  DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Wishlist_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt]  DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Wishlist_UpdatedAt]  DEFAULT GETUTCDATE(),
    [CreatedBy]  INT            NULL,
    [UpdatedBy]  INT            NULL,
    [IsActive]   BIT            NOT NULL  CONSTRAINT [DF_Wishlist_IsActive]   DEFAULT 1,
    [IsDeleted]  BIT            NOT NULL  CONSTRAINT [DF_Wishlist_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_Wishlist]                  PRIMARY KEY CLUSTERED ([WishlistId] ASC),
    CONSTRAINT [UQ_Wishlist_UserProduct]      UNIQUE ([UserId], [ProductId]),

    CONSTRAINT [FK_Wishlist_UserId]           FOREIGN KEY ([UserId])    REFERENCES [dbo].[Users]    ([UserId]),
    CONSTRAINT [FK_Wishlist_ProductId]        FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products] ([ProductId]),
    CONSTRAINT [FK_Wishlist_CreatedBy]        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]    ([UserId]),
    CONSTRAINT [FK_Wishlist_UpdatedBy]        FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]    ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Wishlist_UserId]
    ON [dbo].[Wishlist] ([UserId] ASC)
    WHERE [IsDeleted] = 0;
GO
