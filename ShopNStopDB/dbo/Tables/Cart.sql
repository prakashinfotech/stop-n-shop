CREATE TABLE [dbo].[Cart]
(
    [CartId]       INT            NOT NULL  IDENTITY(1,1),
    [UserId]       INT            NOT NULL,
    [ProductId]    INT            NOT NULL,
    [VariantId]    INT            NOT NULL,
    [Quantity]     INT            NOT NULL  CONSTRAINT [DF_Cart_Quantity]       DEFAULT 1,
    [AddedAt]      DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Cart_AddedAt]        DEFAULT GETUTCDATE(),
    [SavedForLater] BIT           NOT NULL  CONSTRAINT [DF_Cart_SavedForLater]  DEFAULT 0,

    [CreatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Cart_CreatedAt]      DEFAULT GETUTCDATE(),
    [UpdatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Cart_UpdatedAt]      DEFAULT GETUTCDATE(),
    [CreatedBy]    INT            NULL,
    [UpdatedBy]    INT            NULL,
    [IsActive]     BIT            NOT NULL  CONSTRAINT [DF_Cart_IsActive]       DEFAULT 1,
    [IsDeleted]    BIT            NOT NULL  CONSTRAINT [DF_Cart_IsDeleted]      DEFAULT 0,

    CONSTRAINT [PK_Cart]                    PRIMARY KEY CLUSTERED ([CartId] ASC),
    CONSTRAINT [UQ_Cart_UserVariant]        UNIQUE ([UserId], [VariantId]),

    CONSTRAINT [FK_Cart_UserId]             FOREIGN KEY ([UserId])    REFERENCES [dbo].[Users]           ([UserId]),
    CONSTRAINT [FK_Cart_ProductId]          FOREIGN KEY ([ProductId]) REFERENCES [dbo].[Products]        ([ProductId]),
    CONSTRAINT [FK_Cart_VariantId]          FOREIGN KEY ([VariantId]) REFERENCES [dbo].[ProductVariants] ([VariantId]),
    CONSTRAINT [FK_Cart_CreatedBy]          FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]           ([UserId]),
    CONSTRAINT [FK_Cart_UpdatedBy]          FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]           ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Cart_UserId]
    ON [dbo].[Cart] ([UserId] ASC, [SavedForLater] ASC)
    WHERE [IsDeleted] = 0;
GO
