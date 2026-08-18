CREATE TABLE [dbo].[Users]
(
    [UserId]           INT            NOT NULL  IDENTITY(1,1),
    [Email]            NVARCHAR(256)  NOT NULL,
    [Mobile]           NVARCHAR(15)   NULL,
    [PasswordHash]     NVARCHAR(500)  NOT NULL,
    [RoleId]           TINYINT        NOT NULL,
    [FirstName]        NVARCHAR(100)  NULL,
    [LastName]         NVARCHAR(100)  NULL,
    [ProfileImageUrl]  NVARCHAR(500)  NULL,
    [IsEmailVerified]  BIT            NOT NULL  CONSTRAINT [DF_Users_IsEmailVerified]   DEFAULT 0,
    [IsMobileVerified] BIT            NOT NULL  CONSTRAINT [DF_Users_IsMobileVerified]  DEFAULT 0,
    [IsApproved]       BIT            NOT NULL  CONSTRAINT [DF_Users_IsApproved]        DEFAULT 0,
    [LastLoginAt]      DATETIME2(0)   NULL,
    [LoyaltyPoints]    INT            NOT NULL  CONSTRAINT [DF_Users_LoyaltyPoints]     DEFAULT 0,
    [ReferralCode]     NVARCHAR(20)   NULL,
    [IsFirstLogin]     BIT            NOT NULL  CONSTRAINT [DF_Users_IsFirstLogin]      DEFAULT 1,

    [CreatedAt]        DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Users_CreatedAt]         DEFAULT GETUTCDATE(),
    [UpdatedAt]        DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Users_UpdatedAt]         DEFAULT GETUTCDATE(),
    [CreatedBy]        INT            NULL,
    [UpdatedBy]        INT            NULL,
    [IsActive]         BIT            NOT NULL  CONSTRAINT [DF_Users_IsActive]          DEFAULT 1,
    [IsDeleted]        BIT            NOT NULL  CONSTRAINT [DF_Users_IsDeleted]         DEFAULT 0,

    CONSTRAINT [PK_Users]            PRIMARY KEY CLUSTERED ([UserId] ASC),
    CONSTRAINT [UQ_Users_Email]      UNIQUE ([Email]),
    CONSTRAINT [UQ_Users_Mobile]     UNIQUE ([Mobile]),
    CONSTRAINT [UQ_Users_Referral]   UNIQUE ([ReferralCode]),

    CONSTRAINT [FK_Users_RoleId]     FOREIGN KEY ([RoleId])    REFERENCES [dbo].[Roles] ([RoleId]),
    -- Self-referencing audit FKs — NULL on first admin seed row
    CONSTRAINT [FK_Users_CreatedBy]  FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_Users_UpdatedBy]  FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Users_RoleId]
    ON [dbo].[Users] ([RoleId] ASC)
    WHERE [IsDeleted] = 0;
GO

CREATE NONCLUSTERED INDEX [IX_Users_IsDeleted]
    ON [dbo].[Users] ([IsDeleted] ASC, [IsActive] ASC);
GO
