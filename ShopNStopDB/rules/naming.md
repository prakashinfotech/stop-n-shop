## DB Naming Conventions

- Stored Procedures: `usp_Module_Entity_Action` (e.g., `usp_Auth_User_Login`)
- Functions: `fn_ActionOrPurpose` (e.g., `fn_GenerateSlug`)
- Triggers: `tr_TableName_Purpose` (e.g., `tr_Orders_Audit`)
- Views: `vw_DescriptiveName` (e.g., `vw_ProductListing`)
- Tables: PascalCase, plural (e.g., `Products`, `OrderItems`)
- Columns: PascalCase singular (e.g., `UserId`, `CreatedAt`)
- Indexes: `IX_TableName_ColumnName`
- Foreign Keys: `FK_TableName_ReferencedTable`
- Primary Keys: `PK_TableName`

Modules for SP naming: Auth, Catalog, Commerce, Engagement, Notification, Pricing, Seller, Admin, CMS
