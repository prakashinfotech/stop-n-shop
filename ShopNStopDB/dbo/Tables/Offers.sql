CREATE TABLE [dbo].[Offers]
(
    [OfferId]             INT             NOT NULL  IDENTITY(1,1),
    [OfferName]           NVARCHAR(300)   NOT NULL,
    [OfferType]           TINYINT         NOT NULL,  -- 1=Flat, 2=Percentage, 3=BOGO
    [DiscountValue]       DECIMAL(18,2)   NOT NULL,
    [MinOrderValue]       DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_Offers_MinOrderValue]       DEFAULT 0,
    [MaxDiscountCap]      DECIMAL(18,2)   NULL,
    [StartDate]           DATETIME2(0)    NOT NULL,
    [EndDate]             DATETIME2(0)    NOT NULL,
    [ApplicableOn]        TINYINT         NOT NULL,  -- 1=Product, 2=Brand, 3=Category, 4=Cart
    [EntityId]            INT             NULL,
    [UsageLimitTotal]     INT             NULL,
    [UsageLimitPerUser]   TINYINT         NOT NULL  CONSTRAINT [DF_Offers_UsageLimitPerUser]   DEFAULT 1,
    [CurrentUsageCount]   INT             NOT NULL  CONSTRAINT [DF_Offers_CurrentUsageCount]   DEFAULT 0,

    [CreatedAt]           DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Offers_CreatedAt]            DEFAULT GETUTCDATE(),
    [UpdatedAt]           DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Offers_UpdatedAt]            DEFAULT GETUTCDATE(),
    [CreatedBy]           INT             NULL,
    [UpdatedBy]           INT             NULL,
    [IsActive]            BIT             NOT NULL  CONSTRAINT [DF_Offers_IsActive]             DEFAULT 1,
    [IsDeleted]           BIT             NOT NULL  CONSTRAINT [DF_Offers_IsDeleted]            DEFAULT 0,

    CONSTRAINT [PK_Offers]              PRIMARY KEY CLUSTERED ([OfferId] ASC),
    CONSTRAINT [CK_Offers_OfferType]    CHECK ([OfferType]    IN (1, 2, 3)),
    CONSTRAINT [CK_Offers_ApplicableOn] CHECK ([ApplicableOn] IN (1, 2, 3, 4)),

    CONSTRAINT [FK_Offers_CreatedBy]    FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_Offers_UpdatedBy]    FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Offers_ActiveDate]
    ON [dbo].[Offers] ([StartDate] ASC, [EndDate] ASC, [ApplicableOn] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
