CREATE TABLE [dbo].[Reviews]
(
    [ReviewId]          INT            NOT NULL  IDENTITY(1,1),
    [ProductId]         INT            NOT NULL,
    [UserId]            INT            NOT NULL,
    [OrderItemId]       INT            NULL,
    [Rating]            TINYINT        NOT NULL,
    [Title]             NVARCHAR(200)  NULL,
    [Body]              NVARCHAR(2000) NULL,
    [IsVerifiedPurchase] BIT           NOT NULL  CONSTRAINT [DF_Reviews_IsVerifiedPurchase]  DEFAULT 0,
    [HelpfulCount]      INT            NOT NULL  CONSTRAINT [DF_Reviews_HelpfulCount]        DEFAULT 0,
    [IsApproved]        BIT            NOT NULL  CONSTRAINT [DF_Reviews_IsApproved]          DEFAULT 0,
    [ApprovedBy]        INT            NULL,
    [SentimentScore]    DECIMAL(4,3)   NULL,

    [CreatedAt]         DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Reviews_CreatedAt]           DEFAULT GETUTCDATE(),
    [UpdatedAt]         DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Reviews_UpdatedAt]           DEFAULT GETUTCDATE(),
    [CreatedBy]         INT            NULL,
    [UpdatedBy]         INT            NULL,
    [IsActive]          BIT            NOT NULL  CONSTRAINT [DF_Reviews_IsActive]            DEFAULT 1,
    [IsDeleted]         BIT            NOT NULL  CONSTRAINT [DF_Reviews_IsDeleted]           DEFAULT 0,

    CONSTRAINT [PK_Reviews]                    PRIMARY KEY CLUSTERED ([ReviewId] ASC),
    CONSTRAINT [UQ_Reviews_UserOrderItem]      UNIQUE ([UserId], [OrderItemId]),
    CONSTRAINT [CK_Reviews_Rating]             CHECK ([Rating] BETWEEN 1 AND 5),

    CONSTRAINT [FK_Reviews_ProductId]          FOREIGN KEY ([ProductId])   REFERENCES [dbo].[Products]   ([ProductId]),
    CONSTRAINT [FK_Reviews_UserId]             FOREIGN KEY ([UserId])      REFERENCES [dbo].[Users]      ([UserId]),
    CONSTRAINT [FK_Reviews_OrderItemId]        FOREIGN KEY ([OrderItemId]) REFERENCES [dbo].[OrderItems] ([OrderItemId]),
    CONSTRAINT [FK_Reviews_ApprovedBy]         FOREIGN KEY ([ApprovedBy])  REFERENCES [dbo].[Users]      ([UserId]),
    CONSTRAINT [FK_Reviews_CreatedBy]          FOREIGN KEY ([CreatedBy])   REFERENCES [dbo].[Users]      ([UserId]),
    CONSTRAINT [FK_Reviews_UpdatedBy]          FOREIGN KEY ([UpdatedBy])   REFERENCES [dbo].[Users]      ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Reviews_ProductId]
    ON [dbo].[Reviews] ([ProductId] ASC, [IsApproved] ASC, [Rating] DESC)
    WHERE [IsDeleted] = 0;
GO
