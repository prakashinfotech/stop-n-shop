CREATE TABLE [dbo].[SellerSLAs]
(
    [SellerSlaId]        INT             NOT NULL  IDENTITY(1,1),
    [SellerId]           INT             NOT NULL,
    [DispatchHours]      INT             NOT NULL  CONSTRAINT [DF_SellerSLAs_DispatchHours]    DEFAULT 24,
    [DeliveryDays]       INT             NOT NULL  CONSTRAINT [DF_SellerSLAs_DeliveryDays]     DEFAULT 5,
    [RefundDays]         INT             NOT NULL  CONSTRAINT [DF_SellerSLAs_RefundDays]       DEFAULT 7,
    [CancellationCapPct] DECIMAL(5,2)    NOT NULL  CONSTRAINT [DF_SellerSLAs_CancellationCap]  DEFAULT 5.00,
    [ReturnCapPct]       DECIMAL(5,2)    NOT NULL  CONSTRAINT [DF_SellerSLAs_ReturnCap]        DEFAULT 10.00,
    [EffectiveFrom]      DATE            NOT NULL,

    [CreatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerSLAs_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerSLAs_UpdatedAt] DEFAULT GETUTCDATE(),
    [CreatedBy]          INT             NULL,
    [UpdatedBy]          INT             NULL,
    [IsActive]           BIT             NOT NULL  CONSTRAINT [DF_SellerSLAs_IsActive]  DEFAULT 1,
    [IsDeleted]          BIT             NOT NULL  CONSTRAINT [DF_SellerSLAs_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_SellerSLAs]           PRIMARY KEY CLUSTERED ([SellerSlaId] ASC),
    CONSTRAINT [FK_SellerSLAs_SellerId]  FOREIGN KEY ([SellerId])  REFERENCES [dbo].[Sellers] ([SellerId]),
    CONSTRAINT [FK_SellerSLAs_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_SellerSLAs_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]   ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SellerSLAs_SellerId]
    ON [dbo].[SellerSLAs] ([SellerId] ASC)
    WHERE [IsDeleted] = 0;
GO
