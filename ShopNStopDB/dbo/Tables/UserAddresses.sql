CREATE TABLE [dbo].[UserAddresses]
(
    [AddressId]    INT            NOT NULL  IDENTITY(1,1),
    [UserId]       INT            NOT NULL,
    [Label]        NVARCHAR(50)   NULL,                    -- Home / Work / Other
    [AddressLine1] NVARCHAR(300)  NOT NULL,
    [AddressLine2] NVARCHAR(300)  NULL,
    [City]         NVARCHAR(100)  NOT NULL,
    [State]        NVARCHAR(100)  NOT NULL,
    [PinCode]      NVARCHAR(10)   NOT NULL,
    [Country]      NVARCHAR(100)  NOT NULL  CONSTRAINT [DF_UserAddresses_Country]    DEFAULT N'India',
    [Latitude]     DECIMAL(9,6)   NULL,
    [Longitude]    DECIMAL(9,6)   NULL,
    [IsDefault]    BIT            NOT NULL  CONSTRAINT [DF_UserAddresses_IsDefault]  DEFAULT 0,

    [CreatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_UserAddresses_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt]    DATETIME2(0)   NOT NULL  CONSTRAINT [DF_UserAddresses_UpdatedAt]  DEFAULT GETUTCDATE(),
    [CreatedBy]    INT            NULL,
    [UpdatedBy]    INT            NULL,
    [IsActive]     BIT            NOT NULL  CONSTRAINT [DF_UserAddresses_IsActive]   DEFAULT 1,
    [IsDeleted]    BIT            NOT NULL  CONSTRAINT [DF_UserAddresses_IsDeleted]  DEFAULT 0,

    CONSTRAINT [PK_UserAddresses]          PRIMARY KEY CLUSTERED ([AddressId] ASC),

    CONSTRAINT [FK_UserAddresses_UserId]   FOREIGN KEY ([UserId])    REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_UserAddresses_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users] ([UserId]),
    CONSTRAINT [FK_UserAddresses_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users] ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_UserAddresses_UserId]
    ON [dbo].[UserAddresses] ([UserId] ASC)
    WHERE [IsDeleted] = 0;
GO
