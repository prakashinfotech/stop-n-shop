CREATE TABLE [dbo].[Coupons]
(
    [CouponId]   INT            NOT NULL  IDENTITY(1,1),
    [CouponCode] NVARCHAR(50)   NOT NULL,
    [OfferId]    INT            NOT NULL,

    [CreatedAt]  DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Coupons_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt]  DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Coupons_UpdatedAt]  DEFAULT GETUTCDATE(),
    [CreatedBy]  INT            NULL,
    [UpdatedBy]  INT            NULL,
    [IsActive]   BIT            NOT NULL  CONSTRAINT [DF_Coupons_IsActive]   DEFAULT 1,
    [IsDeleted]  BIT            NOT NULL  CONSTRAINT [DF_Coupons_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_Coupons]            PRIMARY KEY CLUSTERED ([CouponId] ASC),
    CONSTRAINT [UQ_Coupons_CouponCode] UNIQUE ([CouponCode]),

    CONSTRAINT [FK_Coupons_OfferId]    FOREIGN KEY ([OfferId])    REFERENCES [dbo].[Offers] ([OfferId]),
    CONSTRAINT [FK_Coupons_CreatedBy]  FOREIGN KEY ([CreatedBy])  REFERENCES [dbo].[Users]  ([UserId]),
    CONSTRAINT [FK_Coupons_UpdatedBy]  FOREIGN KEY ([UpdatedBy])  REFERENCES [dbo].[Users]  ([UserId])
);
GO
