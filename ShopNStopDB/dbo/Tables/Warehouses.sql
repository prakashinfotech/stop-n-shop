CREATE TABLE [dbo].[Warehouses]
(
    [WarehouseId]   INT             NOT NULL  IDENTITY(1,1),
    [Code]          NVARCHAR(50)    NOT NULL,
    [Name]          NVARCHAR(200)   NOT NULL,
    [SellerId]      INT             NULL,            -- NULL = platform/1P warehouse
    [AddressLine1]  NVARCHAR(200)   NULL,
    [AddressLine2]  NVARCHAR(200)   NULL,
    [City]          NVARCHAR(100)   NULL,
    [State]         NVARCHAR(100)   NULL,
    [PinCode]       NVARCHAR(20)    NULL,
    [Country]       NVARCHAR(100)   NOT NULL  CONSTRAINT [DF_Warehouses_Country] DEFAULT N'India',

    [CreatedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Warehouses_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]     DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Warehouses_UpdatedAt] DEFAULT GETUTCDATE(),
    [CreatedBy]     INT             NULL,
    [UpdatedBy]     INT             NULL,
    [IsActive]      BIT             NOT NULL  CONSTRAINT [DF_Warehouses_IsActive]  DEFAULT 1,
    [IsDeleted]     BIT             NOT NULL  CONSTRAINT [DF_Warehouses_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_Warehouses]            PRIMARY KEY CLUSTERED ([WarehouseId] ASC),
    CONSTRAINT [UQ_Warehouses_Code]       UNIQUE ([Code]),
    CONSTRAINT [FK_Warehouses_SellerId]   FOREIGN KEY ([SellerId])  REFERENCES [dbo].[Sellers] ([SellerId]),
    CONSTRAINT [FK_Warehouses_CreatedBy]  FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_Warehouses_UpdatedBy]  FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]   ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_Warehouses_SellerId]
    ON [dbo].[Warehouses] ([SellerId] ASC)
    WHERE [IsDeleted] = 0;
GO
