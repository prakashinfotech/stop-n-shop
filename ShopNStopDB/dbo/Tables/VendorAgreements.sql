CREATE TABLE [dbo].[VendorAgreements]
(
    [AgreementId]        INT             NOT NULL  IDENTITY(1,1),
    [SellerId]           INT             NOT NULL,
    [Version]            NVARCHAR(20)    NOT NULL,
    [AcceptedAt]         DATETIME2(0)    NOT NULL  CONSTRAINT [DF_VendorAgreements_AcceptedAt] DEFAULT GETUTCDATE(),
    [AcceptedIp]         NVARCHAR(45)    NULL,
    [AcceptedUserAgent]  NVARCHAR(500)   NULL,
    [DocumentUrl]        NVARCHAR(500)   NULL,

    [CreatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_VendorAgreements_CreatedAt] DEFAULT GETUTCDATE(),
    [CreatedBy]          INT             NULL,
    [IsActive]           BIT             NOT NULL  CONSTRAINT [DF_VendorAgreements_IsActive]  DEFAULT 1,
    [IsDeleted]          BIT             NOT NULL  CONSTRAINT [DF_VendorAgreements_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_VendorAgreements]           PRIMARY KEY CLUSTERED ([AgreementId] ASC),
    CONSTRAINT [FK_VendorAgreements_SellerId]  FOREIGN KEY ([SellerId])  REFERENCES [dbo].[Sellers] ([SellerId]),
    CONSTRAINT [FK_VendorAgreements_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]   ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_VendorAgreements_SellerId]
    ON [dbo].[VendorAgreements] ([SellerId] ASC)
    WHERE [IsDeleted] = 0;
GO
