CREATE TABLE [dbo].[Wallets]
(
    [WalletId]   INT            NOT NULL  IDENTITY(1,1),
    [UserId]     INT            NOT NULL,
    [Balance]    DECIMAL(18,2) NOT NULL  CONSTRAINT [DF_Wallets_Balance]    DEFAULT 0.00,

    [CreatedAt]  DATETIME2(0)  NOT NULL  CONSTRAINT [DF_Wallets_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt]  DATETIME2(0)  NOT NULL  CONSTRAINT [DF_Wallets_UpdatedAt]  DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_Wallets]          PRIMARY KEY CLUSTERED ([WalletId] ASC),
    CONSTRAINT [UQ_Wallets_UserId]   UNIQUE ([UserId]),
    CONSTRAINT [FK_Wallets_UserId]   FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Wallets_UserId]
    ON [dbo].[Wallets] ([UserId] ASC);
GO
