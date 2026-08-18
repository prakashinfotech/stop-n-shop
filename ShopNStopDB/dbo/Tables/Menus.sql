CREATE TABLE [dbo].[Menus]
(
    [MenuId]    INT            NOT NULL  IDENTITY(1,1),
    [MenuName]  NVARCHAR(100)  NOT NULL,
    [SlugUrl]   NVARCHAR(200)  NOT NULL,
    [SortOrder] INT            NOT NULL  CONSTRAINT [DF_Menus_SortOrder] DEFAULT 0,
    [IsActive]  BIT            NOT NULL  CONSTRAINT [DF_Menus_IsActive]  DEFAULT 1,
    [IsDeleted] BIT            NOT NULL  CONSTRAINT [DF_Menus_IsDeleted] DEFAULT 0,
    [CreatedAt] DATETIME2(0)   NOT NULL  CONSTRAINT [DF_Menus_CreatedAt] DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_Menus]         PRIMARY KEY CLUSTERED ([MenuId] ASC),
    CONSTRAINT [UQ_Menus_SlugUrl] UNIQUE ([SlugUrl])
);
GO
