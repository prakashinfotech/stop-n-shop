CREATE TABLE [dbo].[Notifications]
(
    [NotificationId]   INT             NOT NULL  IDENTITY(1,1),
    [UserId]           INT             NOT NULL,
    [Title]            NVARCHAR(300)   NOT NULL,
    [Body]             NVARCHAR(1000)  NOT NULL,
    [NotificationType] TINYINT         NOT NULL,  -- 1=Order,2=Offer,3=Review,4=System,5=Seller
    [EntityType]       NVARCHAR(50)    NULL,
    [EntityId]         INT             NULL,
    [IsRead]           BIT             NOT NULL  CONSTRAINT [DF_Notifications_IsRead]    DEFAULT 0,
    [ReadAt]           DATETIME2(0)    NULL,
    [Channel]          TINYINT         NOT NULL  CONSTRAINT [DF_Notifications_Channel]   DEFAULT 1,  -- 1=InApp,2=Email,3=SMS,4=Push
    [SentAt]           DATETIME2(0)    NULL,

    [CreatedAt]        DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Notifications_CreatedAt] DEFAULT GETUTCDATE(),
    [IsDeleted]        BIT             NOT NULL  CONSTRAINT [DF_Notifications_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_Notifications]                    PRIMARY KEY CLUSTERED ([NotificationId] ASC),
    CONSTRAINT [CK_Notifications_NotificationType]   CHECK ([NotificationType] IN (1, 2, 3, 4, 5)),
    CONSTRAINT [CK_Notifications_Channel]            CHECK ([Channel]           IN (1, 2, 3, 4)),

    CONSTRAINT [FK_Notifications_UserId]             FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Notifications_UserId]
    ON [dbo].[Notifications] ([UserId] ASC, [IsRead] ASC, [CreatedAt] DESC)
    WHERE [IsDeleted] = 0;
GO
