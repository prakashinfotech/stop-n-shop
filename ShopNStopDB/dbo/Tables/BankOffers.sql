CREATE TABLE [dbo].[BankOffers]
(
    [BankOfferId]   INT             NOT NULL  IDENTITY(1,1),
    [Title]         NVARCHAR(300)   NOT NULL,
    [Description]   NVARCHAR(MAX)   NULL,
    [MinSpend]      DECIMAL(18,2)   NULL,
    [MaxDiscount]   DECIMAL(18,2)   NULL,
    [TermsUrl]      NVARCHAR(500)   NULL,
    [SortOrder]     INT             NOT NULL  CONSTRAINT [DF_BankOffers_SortOrder] DEFAULT 0,

    [CreatedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_BankOffers_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_BankOffers_UpdatedAt] DEFAULT GETUTCDATE(),
    [IsActive]      BIT             NOT NULL  CONSTRAINT [DF_BankOffers_IsActive]  DEFAULT 1,
    [IsDeleted]     BIT             NOT NULL  CONSTRAINT [DF_BankOffers_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_BankOffers] PRIMARY KEY CLUSTERED ([BankOfferId] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_BankOffers_Active]
    ON [dbo].[BankOffers] ([SortOrder] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
