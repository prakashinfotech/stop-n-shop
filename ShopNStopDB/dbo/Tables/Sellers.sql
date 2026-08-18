CREATE TABLE [dbo].[Sellers]
(
    [SellerId]          INT             NOT NULL  IDENTITY(1,1),
    [UserId]            INT             NOT NULL,
    [BusinessName]      NVARCHAR(300)   NOT NULL,
    [GstNumber]         NVARCHAR(20)    NULL,
    [PanNumber]         NVARCHAR(20)    NULL,
    [BusinessAddressId] INT             NULL,
    [BankAccountNumber] NVARCHAR(50)    NULL,
    [BankIfscCode]      NVARCHAR(20)    NULL,
    [BankName]          NVARCHAR(100)   NULL,
    [ApprovalStatus]    TINYINT         NOT NULL  CONSTRAINT [DF_Sellers_ApprovalStatus]  DEFAULT 1,  -- 1=Pending,2=Approved,3=Rejected,4=Suspended
    [ApprovedBy]        INT             NULL,
    [ApprovedAt]        DATETIME2(0)    NULL,
    [RejectionReason]   NVARCHAR(500)   NULL,
    [CommissionRate]    DECIMAL(5,2)    NOT NULL  CONSTRAINT [DF_Sellers_CommissionRate]  DEFAULT 10.00,

    -- Extended profile fields (used by seller signup / portal flow)
    [OwnerName]            NVARCHAR(200)   NULL,
    [DisplayName]          NVARCHAR(200)   NULL,
    [StoreDescription]     NVARCHAR(MAX)   NULL,
    [Description]          NVARCHAR(MAX)   NULL,
    [BannerUrl]            NVARCHAR(500)   NULL,
    [LogoUrl]              NVARCHAR(500)   NULL,
    [SupportEmail]         NVARCHAR(256)   NULL,
    [SupportPhone]         NVARCHAR(20)    NULL,
    [Address]              NVARCHAR(300)   NULL,
    [City]                 NVARCHAR(100)   NULL,
    [State]                NVARCHAR(100)   NULL,
    [Pincode]              NVARCHAR(10)    NULL,
    [IsIdVerified]         BIT             NOT NULL  CONSTRAINT [DF_Sellers_IsIdVerified]        DEFAULT 0,
    [OnboardingCompleted]  BIT             NOT NULL  CONSTRAINT [DF_Sellers_OnboardingCompleted] DEFAULT 0,
    [PickupAddressLine1]   NVARCHAR(300)   NULL,
    [PickupAddressLine2]   NVARCHAR(300)   NULL,
    [PickupCity]           NVARCHAR(100)   NULL,
    [PickupState]          NVARCHAR(100)   NULL,
    [PickupPincode]        NVARCHAR(10)    NULL,
    [PickupLandmark]       NVARCHAR(200)   NULL,
    [SelectedCategories]   NVARCHAR(MAX)   NULL,

    [CreatedAt]         DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Sellers_CreatedAt]       DEFAULT GETUTCDATE(),
    [UpdatedAt]         DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Sellers_UpdatedAt]       DEFAULT GETUTCDATE(),
    [CreatedBy]         INT             NULL,
    [UpdatedBy]         INT             NULL,
    [IsActive]          BIT             NOT NULL  CONSTRAINT [DF_Sellers_IsActive]        DEFAULT 1,
    [IsDeleted]         BIT             NOT NULL  CONSTRAINT [DF_Sellers_IsDeleted]       DEFAULT 0,

    CONSTRAINT [PK_Sellers]                   PRIMARY KEY CLUSTERED ([SellerId] ASC),
    CONSTRAINT [UQ_Sellers_UserId]            UNIQUE ([UserId]),
    CONSTRAINT [CK_Sellers_ApprovalStatus]    CHECK ([ApprovalStatus] IN (1, 2, 3, 4)),

    CONSTRAINT [FK_Sellers_UserId]            FOREIGN KEY ([UserId])            REFERENCES [dbo].[Users]         ([UserId]),
    CONSTRAINT [FK_Sellers_BusinessAddressId] FOREIGN KEY ([BusinessAddressId]) REFERENCES [dbo].[UserAddresses] ([AddressId]),
    CONSTRAINT [FK_Sellers_ApprovedBy]        FOREIGN KEY ([ApprovedBy])        REFERENCES [dbo].[Users]         ([UserId]),
    CONSTRAINT [FK_Sellers_CreatedBy]         FOREIGN KEY ([CreatedBy])         REFERENCES [dbo].[Users]         ([UserId]),
    CONSTRAINT [FK_Sellers_UpdatedBy]         FOREIGN KEY ([UpdatedBy])         REFERENCES [dbo].[Users]         ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Sellers_ApprovalStatus]
    ON [dbo].[Sellers] ([ApprovalStatus] ASC)
    WHERE [IsDeleted] = 0;
GO
