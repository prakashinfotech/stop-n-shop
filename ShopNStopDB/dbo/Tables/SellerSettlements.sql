CREATE TABLE [dbo].[SellerSettlements]
(
    [SettlementId]       INT             NOT NULL  IDENTITY(1,1),
    [SellerId]           INT             NOT NULL,
    [PeriodStart]        DATE            NOT NULL,
    [PeriodEnd]          DATE            NOT NULL,
    [GrossSales]         DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_SellerSettlements_GrossSales]      DEFAULT 0,
    [CommissionAmount]   DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_SellerSettlements_Commission]      DEFAULT 0,
    [TdsAmount]          DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_SellerSettlements_Tds]             DEFAULT 0,
    [PenaltyAmount]      DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_SellerSettlements_Penalty]         DEFAULT 0,
    [RefundAmount]       DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_SellerSettlements_Refund]          DEFAULT 0,
    [NetPayout]          DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_SellerSettlements_NetPayout]       DEFAULT 0,
    [Status]             TINYINT         NOT NULL  CONSTRAINT [DF_SellerSettlements_Status]          DEFAULT 1,
        -- 1=Pending, 2=Paid, 3=OnHold, 4=Failed
    [PaidAt]             DATETIME2(0)    NULL,
    [UtrNumber]          NVARCHAR(50)    NULL,
    [BankAccountId]      INT             NULL,
    [Notes]              NVARCHAR(500)   NULL,

    [CreatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerSettlements_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerSettlements_UpdatedAt] DEFAULT GETUTCDATE(),
    [CreatedBy]          INT             NULL,
    [UpdatedBy]          INT             NULL,
    [IsActive]           BIT             NOT NULL  CONSTRAINT [DF_SellerSettlements_IsActive]  DEFAULT 1,
    [IsDeleted]          BIT             NOT NULL  CONSTRAINT [DF_SellerSettlements_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_SellerSettlements]              PRIMARY KEY CLUSTERED ([SettlementId] ASC),
    CONSTRAINT [UQ_SellerSettlements_Period]       UNIQUE ([SellerId], [PeriodStart], [PeriodEnd]),
    CONSTRAINT [CK_SellerSettlements_Status]       CHECK ([Status] IN (1, 2, 3, 4)),
    CONSTRAINT [FK_SellerSettlements_SellerId]     FOREIGN KEY ([SellerId])      REFERENCES [dbo].[Sellers]            ([SellerId]),
    CONSTRAINT [FK_SellerSettlements_BankAccount]  FOREIGN KEY ([BankAccountId]) REFERENCES [dbo].[SellerBankAccounts] ([BankAccountId]),
    CONSTRAINT [FK_SellerSettlements_CreatedBy]    FOREIGN KEY ([CreatedBy])     REFERENCES [dbo].[Users]              ([UserId]),
    CONSTRAINT [FK_SellerSettlements_UpdatedBy]    FOREIGN KEY ([UpdatedBy])     REFERENCES [dbo].[Users]              ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SellerSettlements_Seller_Period]
    ON [dbo].[SellerSettlements] ([SellerId] ASC, [PeriodEnd] DESC)
    WHERE [IsDeleted] = 0;
GO
