Scaffold a new SQL Server table script for the ShopNStopDB project.

Always include these standard columns:
- `Id` INT IDENTITY(1,1) PRIMARY KEY
- `CreatedAt` DATETIME2 DEFAULT GETUTCDATE()
- `UpdatedAt` DATETIME2 DEFAULT GETUTCDATE()
- `IsDeleted` BIT DEFAULT 0

Follow these rules:
- Place the file in `ShopNStopDB/dbo/Tables/`
- File name matches table name exactly (e.g., `Products.sql`)
- Add foreign key constraints with named constraint format: `FK_TableName_ReferencedTable`
- Add indexes for all foreign key columns and columns used in WHERE clauses
- Add the table to the UpdatedAt trigger in `tr_AllTables_UpdatedAt.sql`
