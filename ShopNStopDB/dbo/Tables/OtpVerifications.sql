CREATE TABLE [dbo].[OtpVerifications]
(
    [OtpId]        INT            NOT NULL  IDENTITY(1,1),
    [UserId]       INT            NOT NULL,
    [OtpCode]      NVARCHAR(10)   NOT NULL,
    [OtpType]      TINYINT        NOT NULL,  -- 1=Email, 2=Mobile
    [ExpiresAt]    DATETIME2(0)   NOT NULL,
    [IsUsed]       BIT            NOT NULL  CONSTRAINT [DF_OtpVerifications_IsUsed]        DEFAULT 0,
    [AttemptCount] TINYINT        NOT NULL  CONSTRAINT [DF_OtpVerifications_AttemptCount]  DEFAULT 0,

    [CreatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_OtpVerifications_CreatedAt]     DEFAULT GETUTCDATE(),
    [IsDeleted]    BIT            NOT NULL  CONSTRAINT [DF_OtpVerifications_IsDeleted]     DEFAULT 0,

    CONSTRAINT [PK_OtpVerifications]        PRIMARY KEY CLUSTERED ([OtpId] ASC),
    CONSTRAINT [CK_OtpVerifications_OtpType] CHECK ([OtpType] IN (1, 2)),

    CONSTRAINT [FK_OtpVerifications_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_OtpVerifications_UserId_OtpType]
    ON [dbo].[OtpVerifications] ([UserId] ASC, [OtpType] ASC, [IsUsed] ASC, [IsDeleted] ASC);
GO
