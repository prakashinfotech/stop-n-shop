CREATE TABLE [dbo].[SellerDocuments]
(
    [DocumentId]   INT            NOT NULL  IDENTITY(1,1),
    [SellerId]     INT            NOT NULL,
    [DocumentType] TINYINT        NOT NULL,  -- 1=GST, 2=PAN, 3=FSSAI, 4=Other
    [DocumentUrl]  NVARCHAR(500)  NOT NULL,
    [IsVerified]   BIT            NOT NULL  CONSTRAINT [DF_SellerDocuments_IsVerified]  DEFAULT 0,
    [VerifiedBy]   INT            NULL,

    [CreatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_SellerDocuments_CreatedAt]   DEFAULT GETUTCDATE(),
    [UpdatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_SellerDocuments_UpdatedAt]   DEFAULT GETUTCDATE(),
    [CreatedBy]    INT            NULL,
    [UpdatedBy]    INT            NULL,
    [IsActive]     BIT            NOT NULL  CONSTRAINT [DF_SellerDocuments_IsActive]    DEFAULT 1,
    [IsDeleted]    BIT            NOT NULL  CONSTRAINT [DF_SellerDocuments_IsDeleted]   DEFAULT 0,

    CONSTRAINT [PK_SellerDocuments]              PRIMARY KEY CLUSTERED ([DocumentId] ASC),
    CONSTRAINT [CK_SellerDocuments_DocumentType] CHECK ([DocumentType] IN (1, 2, 3, 4)),

    CONSTRAINT [FK_SellerDocuments_SellerId]     FOREIGN KEY ([SellerId])   REFERENCES [dbo].[Sellers] ([SellerId]),
    CONSTRAINT [FK_SellerDocuments_VerifiedBy]   FOREIGN KEY ([VerifiedBy]) REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_SellerDocuments_CreatedBy]    FOREIGN KEY ([CreatedBy])  REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_SellerDocuments_UpdatedBy]    FOREIGN KEY ([UpdatedBy])  REFERENCES [dbo].[Users]   ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SellerDocuments_SellerId]
    ON [dbo].[SellerDocuments] ([SellerId] ASC)
    WHERE [IsDeleted] = 0;
GO
