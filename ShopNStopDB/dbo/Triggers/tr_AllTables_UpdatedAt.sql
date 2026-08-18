-- Individual AFTER UPDATE triggers to keep UpdatedAt current on all major business tables.
-- SPs always set UpdatedAt explicitly; these triggers act as a safety net for direct DML.

CREATE TRIGGER [dbo].[tr_Brands_UpdatedAt]
ON [dbo].[Brands] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE b SET b.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[Brands] b INNER JOIN inserted i ON b.[BrandId] = i.[BrandId];
END;
GO

CREATE TRIGGER [dbo].[tr_Categories_UpdatedAt]
ON [dbo].[Categories] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE c SET c.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[Categories] c INNER JOIN inserted i ON c.[CategoryId] = i.[CategoryId];
END;
GO

CREATE TRIGGER [dbo].[tr_SubCategories_UpdatedAt]
ON [dbo].[SubCategories] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE sc SET sc.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[SubCategories] sc INNER JOIN inserted i ON sc.[SubCategoryId] = i.[SubCategoryId];
END;
GO

CREATE TRIGGER [dbo].[tr_ProductVariants_UpdatedAt]
ON [dbo].[ProductVariants] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE pv SET pv.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[ProductVariants] pv INNER JOIN inserted i ON pv.[VariantId] = i.[VariantId];
END;
GO

CREATE TRIGGER [dbo].[tr_UserAddresses_UpdatedAt]
ON [dbo].[UserAddresses] AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE ua SET ua.[UpdatedAt] = GETUTCDATE()
    FROM [dbo].[UserAddresses] ua INNER JOIN inserted i ON ua.[AddressId] = i.[AddressId];
END;
GO
