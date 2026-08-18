CREATE TABLE [dbo].[WalletTransactions]
(
    [TransactionId]   INT             NOT NULL  IDENTITY(1,1),
    [WalletId]        INT             NOT NULL,
    [UserId]          INT             NOT NULL,
    [Amount]          DECIMAL(18,2)  NOT NULL,
    [TransactionType] TINYINT         NOT NULL,  -- 1=Credit, 2=Debit
    [ReferenceType]   NVARCHAR(50)    NULL,       -- 'OrderRefund', 'ManualCredit', etc.
    [ReferenceId]     INT             NULL,       -- OrderId or other entity Id
    [Description]     NVARCHAR(300)   NOT NULL,

    [CreatedAt]       DATETIME2(0)   NOT NULL  CONSTRAINT [DF_WalletTransactions_CreatedAt] DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_WalletTransactions]          PRIMARY KEY CLUSTERED ([TransactionId] ASC),
    CONSTRAINT [CK_WalletTransactions_Type]     CHECK ([TransactionType] IN (1, 2)),
    CONSTRAINT [FK_WalletTransactions_WalletId] FOREIGN KEY ([WalletId]) REFERENCES [dbo].[Wallets]  ([WalletId]),
    CONSTRAINT [FK_WalletTransactions_UserId]   FOREIGN KEY ([UserId])   REFERENCES [dbo].[Users]    ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_WalletTransactions_UserId]
    ON [dbo].[WalletTransactions] ([UserId] ASC, [CreatedAt] DESC);
GO
