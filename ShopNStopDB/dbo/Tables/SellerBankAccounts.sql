CREATE TABLE [dbo].[SellerBankAccounts]
(
    [BankAccountId]      INT             NOT NULL  IDENTITY(1,1),
    [SellerId]           INT             NOT NULL,
    [AccountHolderName]  NVARCHAR(200)   NOT NULL,
    [BankName]           NVARCHAR(100)   NOT NULL,
    [AccountNumber]      NVARCHAR(50)    NOT NULL,
    [IfscCode]           NVARCHAR(20)    NOT NULL,
    [BranchName]         NVARCHAR(200)   NULL,
    [IsPrimary]          BIT             NOT NULL  CONSTRAINT [DF_SellerBankAccounts_IsPrimary]   DEFAULT 0,
    [IsVerified]         BIT             NOT NULL  CONSTRAINT [DF_SellerBankAccounts_IsVerified]  DEFAULT 0,
    [VerifiedAt]         DATETIME2(0)    NULL,
    [VerifiedBy]         INT             NULL,

    [CreatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerBankAccounts_CreatedAt]   DEFAULT GETUTCDATE(),
    [UpdatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerBankAccounts_UpdatedAt]   DEFAULT GETUTCDATE(),
    [CreatedBy]          INT             NULL,
    [UpdatedBy]          INT             NULL,
    [IsActive]           BIT             NOT NULL  CONSTRAINT [DF_SellerBankAccounts_IsActive]    DEFAULT 1,
    [IsDeleted]          BIT             NOT NULL  CONSTRAINT [DF_SellerBankAccounts_IsDeleted]   DEFAULT 0,

    CONSTRAINT [PK_SellerBankAccounts]            PRIMARY KEY CLUSTERED ([BankAccountId] ASC),
    CONSTRAINT [FK_SellerBankAccounts_SellerId]   FOREIGN KEY ([SellerId])   REFERENCES [dbo].[Sellers] ([SellerId]),
    CONSTRAINT [FK_SellerBankAccounts_VerifiedBy] FOREIGN KEY ([VerifiedBy]) REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_SellerBankAccounts_CreatedBy]  FOREIGN KEY ([CreatedBy])  REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_SellerBankAccounts_UpdatedBy]  FOREIGN KEY ([UpdatedBy])  REFERENCES [dbo].[Users]   ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SellerBankAccounts_SellerId]
    ON [dbo].[SellerBankAccounts] ([SellerId] ASC)
    WHERE [IsDeleted] = 0;
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_SellerBankAccounts_PrimaryPerSeller]
    ON [dbo].[SellerBankAccounts] ([SellerId] ASC)
    WHERE [IsPrimary] = 1 AND [IsDeleted] = 0;
GO
