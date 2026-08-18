-- Seed critical reference data
-- Schema verified: Roles and GenderTypes have manual PKs, Menus/Categories use IDENTITY

-- Roles: Manual PK (TinyInt)
INSERT INTO [dbo].[Roles] ([RoleId], [RoleName], [Description], [IsActive])
SELECT 1, N'Admin', N'Administrator', 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [RoleId] = 1)
UNION ALL
SELECT 2, N'Buyer', N'Customer', 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [RoleId] = 2)
UNION ALL
SELECT 3, N'Seller', N'Seller', 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [RoleId] = 3);
GO

-- GenderTypes: Manual PK (TinyInt)
INSERT INTO [dbo].[GenderTypes] ([GenderTypeId], [Name], [IsActive])
SELECT 1, N'Men', 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[GenderTypes] WHERE [GenderTypeId] = 1)
UNION ALL
SELECT 2, N'Women', 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[GenderTypes] WHERE [GenderTypeId] = 2)
UNION ALL
SELECT 3, N'Kids', 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[GenderTypes] WHERE [GenderTypeId] = 3)
UNION ALL
SELECT 4, N'Unisex', 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[GenderTypes] WHERE [GenderTypeId] = 4)
UNION ALL
SELECT 5, N'Beauty', 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[GenderTypes] WHERE [GenderTypeId] = 5)
UNION ALL
SELECT 6, N'All', 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[GenderTypes] WHERE [GenderTypeId] = 6);
GO

-- Menus: IDENTITY PK (Int) - let SQL generate MenuId
INSERT INTO [dbo].[Menus] ([MenuName], [SlugUrl], [SortOrder], [IsActive])
SELECT N'MEN', N'men', 1, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Menus] WHERE [SlugUrl] = N'men')
UNION ALL
SELECT N'WOMEN', N'women', 2, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Menus] WHERE [SlugUrl] = N'women')
UNION ALL
SELECT N'KIDS', N'kids', 3, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Menus] WHERE [SlugUrl] = N'kids')
UNION ALL
SELECT N'HOME', N'home', 4, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Menus] WHERE [SlugUrl] = N'home')
UNION ALL
SELECT N'BEAUTY', N'beauty', 5, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Menus] WHERE [SlugUrl] = N'beauty')
UNION ALL
SELECT N'BRANDS', N'brands', 6, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Menus] WHERE [SlugUrl] = N'brands');
GO

-- Categories: IDENTITY PK (Int), FK to Menus (MenuId)
-- Default MenuId = 1, so categories link to first menu by default
INSERT INTO [dbo].[Categories] ([MenuId], [CategoryName], [SlugUrl], [SortOrder], [IsActive])
SELECT 1, N'Clothing', N'clothing', 1, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Categories] WHERE [SlugUrl] = N'clothing')
UNION ALL
SELECT 1, N'Footwear', N'footwear', 2, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Categories] WHERE [SlugUrl] = N'footwear')
UNION ALL
SELECT 1, N'Accessories', N'accessories', 3, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Categories] WHERE [SlugUrl] = N'accessories')
UNION ALL
SELECT 4, N'Home Decor', N'home-decor', 1, 1 WHERE NOT EXISTS (SELECT 1 FROM [dbo].[Categories] WHERE [SlugUrl] = N'home-decor');
GO

PRINT 'Seed data inserted successfully!';
