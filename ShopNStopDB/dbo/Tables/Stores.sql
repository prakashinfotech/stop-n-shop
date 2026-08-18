CREATE TABLE [dbo].[Stores]
(
    [StoreId]      INT             NOT NULL  IDENTITY(1,1),
    [StoreName]    NVARCHAR(200)   NOT NULL,
    [Address]      NVARCHAR(500)   NOT NULL,
    [City]         NVARCHAR(100)   NOT NULL,
    [State]        NVARCHAR(100)   NOT NULL,
    [Pincode]      NVARCHAR(10)    NOT NULL,
    [Lat]          DECIMAL(9, 6)   NULL,
    [Lng]          DECIMAL(9, 6)   NULL,
    [Phone]        NVARCHAR(20)    NULL,

    [CreatedAt]    DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Stores_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]    DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Stores_UpdatedAt] DEFAULT GETUTCDATE(),
    [IsActive]     BIT             NOT NULL  CONSTRAINT [DF_Stores_IsActive]  DEFAULT 1,
    [IsDeleted]    BIT             NOT NULL  CONSTRAINT [DF_Stores_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_Stores] PRIMARY KEY CLUSTERED ([StoreId] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_Stores_City]
    ON [dbo].[Stores] ([City] ASC)
    WHERE [IsDeleted] = 0 AND [IsActive] = 1;
GO
