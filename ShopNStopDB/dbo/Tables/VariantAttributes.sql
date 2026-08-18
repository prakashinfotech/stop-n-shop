CREATE TABLE [dbo].[VariantAttributes]
(
    [AttributeId]    INT             NOT NULL  IDENTITY(1,1),
    [AttributeKey]   NVARCHAR(50)    NOT NULL,    -- 'size' | 'color' | 'material' | 'pattern' | 'fit'
    [DisplayName]    NVARCHAR(100)   NOT NULL,
    [InputType]      NVARCHAR(20)    NOT NULL  CONSTRAINT [DF_VariantAttributes_InputType]  DEFAULT N'select',  -- select | swatch | text
    [SortOrder]      INT             NOT NULL  CONSTRAINT [DF_VariantAttributes_SortOrder]  DEFAULT 0,

    [CreatedAt]      DATETIME2(0)    NOT NULL  CONSTRAINT [DF_VariantAttributes_CreatedAt]  DEFAULT GETUTCDATE(),
    [UpdatedAt]      DATETIME2(0)    NOT NULL  CONSTRAINT [DF_VariantAttributes_UpdatedAt]  DEFAULT GETUTCDATE(),
    [IsActive]       BIT             NOT NULL  CONSTRAINT [DF_VariantAttributes_IsActive]   DEFAULT 1,

    CONSTRAINT [PK_VariantAttributes]        PRIMARY KEY CLUSTERED ([AttributeId] ASC),
    CONSTRAINT [UQ_VariantAttributes_Key]    UNIQUE ([AttributeKey]),
    CONSTRAINT [CK_VariantAttributes_Input]  CHECK ([InputType] IN (N'select', N'swatch', N'text'))
);
GO
