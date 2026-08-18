CREATE TABLE [dbo].[RefreshTokens]
(
    [TokenId]    INT            NOT NULL  IDENTITY(1,1),
    [UserId]     INT            NOT NULL,
    [Token]      NVARCHAR(500)  NOT NULL,
    [ExpiresAt]  DATETIME2(0)   NOT NULL,
    [IsRevoked]  BIT            NOT NULL  CONSTRAINT [DF_RefreshTokens_IsRevoked]  DEFAULT 0,
    [DeviceInfo] NVARCHAR(300)  NULL,
    [IpAddress]  NVARCHAR(50)   NULL,

    [CreatedAt]  DATETIME2(0)   NOT NULL  CONSTRAINT [DF_RefreshTokens_CreatedAt] DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_RefreshTokens]         PRIMARY KEY CLUSTERED ([TokenId] ASC),
    CONSTRAINT [UQ_RefreshTokens_Token]   UNIQUE ([Token]),

    CONSTRAINT [FK_RefreshTokens_UserId]  FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_RefreshTokens_UserId_IsRevoked]
    ON [dbo].[RefreshTokens] ([UserId] ASC, [IsRevoked] ASC, [ExpiresAt] ASC);
GO
