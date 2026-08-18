CREATE TABLE [dbo].[CommissionPlans]
(
    [CommissionPlanId]   INT             NOT NULL  IDENTITY(1,1),
    [PlanName]           NVARCHAR(100)   NOT NULL,
    [CategoryId]         INT             NULL,            -- NULL = applies to all categories
    [CommissionRate]     DECIMAL(5,2)    NOT NULL,        -- percentage, e.g. 10.00
    [MinFee]             DECIMAL(18,2)   NOT NULL  CONSTRAINT [DF_CommissionPlans_MinFee] DEFAULT 0,
    [MaxFee]             DECIMAL(18,2)   NULL,            -- cap, NULL = uncapped
    [TdsRate]            DECIMAL(5,2)    NOT NULL  CONSTRAINT [DF_CommissionPlans_TdsRate] DEFAULT 1.00,
    [EffectiveFrom]      DATE            NOT NULL,
    [EffectiveTo]        DATE            NULL,
    [IsDefault]          BIT             NOT NULL  CONSTRAINT [DF_CommissionPlans_IsDefault] DEFAULT 0,

    [CreatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_CommissionPlans_CreatedAt] DEFAULT GETUTCDATE(),
    [UpdatedAt]          DATETIME2(0)    NOT NULL  CONSTRAINT [DF_CommissionPlans_UpdatedAt] DEFAULT GETUTCDATE(),
    [CreatedBy]          INT             NULL,
    [UpdatedBy]          INT             NULL,
    [IsActive]           BIT             NOT NULL  CONSTRAINT [DF_CommissionPlans_IsActive]  DEFAULT 1,
    [IsDeleted]          BIT             NOT NULL  CONSTRAINT [DF_CommissionPlans_IsDeleted] DEFAULT 0,

    CONSTRAINT [PK_CommissionPlans]            PRIMARY KEY CLUSTERED ([CommissionPlanId] ASC),
    CONSTRAINT [FK_CommissionPlans_CategoryId] FOREIGN KEY ([CategoryId]) REFERENCES [dbo].[Categories] ([CategoryId]),
    CONSTRAINT [FK_CommissionPlans_CreatedBy]  FOREIGN KEY ([CreatedBy])  REFERENCES [dbo].[Users]      ([UserId]),
    CONSTRAINT [FK_CommissionPlans_UpdatedBy]  FOREIGN KEY ([UpdatedBy])  REFERENCES [dbo].[Users]      ([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_CommissionPlans_Category]
    ON [dbo].[CommissionPlans] ([CategoryId] ASC, [EffectiveFrom] DESC)
    WHERE [IsDeleted] = 0;
GO
