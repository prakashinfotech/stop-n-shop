CREATE TABLE [dbo].[SellerWarehouses]
(
    [SellerWarehouseId]  INT             NOT NULL  IDENTITY(1,1),
    [SellerId]           INT             NOT NULL,
    [WarehouseId]        INT             NULL,            -- optional link to platform Warehouses table
    [Name]               NVARCHAR(200)   NOT NULL,
    [ContactName]        NVARCHAR(200)   NULL,
    [ContactPhone]       NVARCHAR(20)    NULL,
    [AddressLine1]       NVARCHAR(300)   NOT NULL,
    [AddressLine2]       NVARCHAR(300)   NULL,
    [City]               NVARCHAR(100)   NOT NULL,
    [State]              NVARCHAR(100)   NOT NULL,
    [Pincode]            NVARCHAR(10)    NOT NULL,
    [IsPrimary]          BIT             NOT NULL  CONSTRAINT [DF_SellerWarehouses_IsPrimary] DEFAULT 0,

    [CreatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerWarehouses_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_SellerWarehouses_UpdatedAt] DEFAULT GETUTCDATE(),
    [CreatedBy]          INT             NULL,
    [UpdatedBy]          INT             NULL,
    [IsActive]           BIT             NOT NULL  CONSTRAINT [DF_SellerWarehouses_IsActive]  DEFAULT 1,
    [IsDeleted]          BIT             NOT NULL  CONSTRAINT [DF_SellerWarehouses_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_SellerWarehouses]           PRIMARY KEY CLUSTERED ([SellerWarehouseId] ASC),
    CONSTRAINT [FK_SellerWarehouses_SellerId]  FOREIGN KEY ([SellerId])  REFERENCES [dbo].[Sellers] ([SellerId]),
    CONSTRAINT [FK_SellerWarehouses_CreatedBy] FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]   ([UserId]),
    CONSTRAINT [FK_SellerWarehouses_UpdatedBy] FOREIGN KEY ([UpdatedBy]) REFERENCES [dbo].[Users]   ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SellerWarehouses_SellerId]
    ON [dbo].[SellerWarehouses] ([SellerId] ASC)
    WHERE [IsDeleted] = 0;
GO
