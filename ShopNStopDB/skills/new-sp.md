Scaffold a new stored procedure for ShopNStopDB.

Naming convention: `usp_Module_Entity_Action`
Examples: `usp_Auth_User_Login`, `usp_Catalog_Product_GetById`, `usp_Commerce_Order_Place`

Modules: Auth, Catalog, Commerce, Engagement, Notification, Pricing, Seller, Admin, CMS

Template to follow:
```sql
CREATE OR ALTER PROCEDURE dbo.usp_Module_Entity_Action
    @Param1 DATATYPE,
    @Param2 DATATYPE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- logic here

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
```

Place the file in `ShopNStopDB/dbo/StoredProcedures/` and add a corresponding entry in `ShopNStopDB.sqlproj`.
