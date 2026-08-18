/*
Post-Deployment Script — runs after every DACPAC publish.
Scripts execute in dependency order; all use MERGE for idempotency.
*/

--:r .\dbo\Data\Seed_Roles.sql
--:r .\dbo\Data\Seed_GenderTypes.sql
--:r .\dbo\Data\Seed_Menus.sql
--:r .\dbo\Data\Seed_Categories.sql
--:r .\dbo\Data\Seed_SubCategories.sql
--:r .\dbo\Data\Seed_AdminUser.sql
--:r .\dbo\Data\Seed_Brands.sql
--:r .\dbo\Data\Seed_DemoSeller.sql
--:r .\dbo\Data\Seed_Products.sql
--:r .\dbo\Data\Seed_Banners.sql
--:r .\dbo\Data\Seed_Stores.sql
--:r .\dbo\Data\Seed_CommissionPlans.sql
--:r .\dbo\Data\Seed_Warehouses.sql
--:r .\dbo\Data\Seed_VariantAttributes.sql
--:r .\dbo\Data\Seed_SubCategoryFormRules.sql
--:r .\dbo\Data\Seed_SubCategoryVariantOptions.sql
