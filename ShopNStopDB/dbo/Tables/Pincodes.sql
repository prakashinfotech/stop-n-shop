CREATE TABLE [dbo].[Pincodes]
(
    [Pincode]        NVARCHAR(10)    NOT NULL,
    [City]           NVARCHAR(100)   NOT NULL,
    [State]          NVARCHAR(100)   NOT NULL,
    [EstimatedDays]  TINYINT         NOT NULL  CONSTRAINT [DF_Pincodes_EstimatedDays] DEFAULT 5,
    [CODAvailable]   BIT             NOT NULL  CONSTRAINT [DF_Pincodes_CODAvailable]  DEFAULT 1,
    [IsActive]       BIT             NOT NULL  CONSTRAINT [DF_Pincodes_IsActive]      DEFAULT 1,
    [CreatedAt]      DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Pincodes_CreatedAt]     DEFAULT GETUTCDATE(),
    [UpdatedAt]      DATETIME2(0)    NOT NULL  CONSTRAINT [DF_Pincodes_UpdatedAt]     DEFAULT GETUTCDATE(),

    CONSTRAINT [PK_Pincodes] PRIMARY KEY CLUSTERED ([Pincode] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_Pincodes_CityState]
    ON [dbo].[Pincodes] ([City] ASC, [State] ASC)
    WHERE [IsActive] = 1;
GO
