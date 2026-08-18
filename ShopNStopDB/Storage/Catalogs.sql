-- Full-text catalog and index for product search.
-- Deployed after table creation via DACPAC post-build step.
-- DISABLED: Full-Text Search not installed on target SQL Server instance

/*
CREATE FULLTEXT CATALOG [StopNShopCatalog] AS DEFAULT;
GO

CREATE FULLTEXT INDEX ON [dbo].[Products]
(
    [ProductName]      LANGUAGE 1033,
    [ShortDescription] LANGUAGE 1033,
    [LongDescription]  LANGUAGE 1033,
    [Tags]             LANGUAGE 1033
)
KEY INDEX [PK_Products]
ON [StopNShopCatalog]
WITH CHANGE_TRACKING AUTO;
GO
*/
