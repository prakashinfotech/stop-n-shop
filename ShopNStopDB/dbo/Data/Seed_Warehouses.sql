-- Seed default platform warehouses. Sellers can be added later via API.
-- Idempotent MERGE keyed on Warehouses.Code.
MERGE [dbo].[Warehouses] AS tgt
USING (VALUES
    (N'WH-MUM-01', N'Mumbai DC',     NULL, N'Andheri Industrial Estate', N'MIDC', N'Mumbai',    N'Maharashtra', N'400093', N'India'),
    (N'WH-BLR-01', N'Bengaluru DC',  NULL, N'Whitefield Logistics Park', NULL,    N'Bengaluru', N'Karnataka',   N'560066', N'India'),
    (N'WH-DEL-01', N'Delhi NCR DC',  NULL, N'Bilaspur Industrial Area',  NULL,    N'Gurugram',  N'Haryana',     N'122413', N'India')
) AS src ([Code], [Name], [SellerId], [AddressLine1], [AddressLine2], [City], [State], [PinCode], [Country])
ON tgt.[Code] = src.[Code]
WHEN MATCHED THEN UPDATE SET
    tgt.[Name]         = src.[Name],
    tgt.[AddressLine1] = src.[AddressLine1],
    tgt.[AddressLine2] = src.[AddressLine2],
    tgt.[City]         = src.[City],
    tgt.[State]        = src.[State],
    tgt.[PinCode]      = src.[PinCode],
    tgt.[Country]      = src.[Country],
    tgt.[UpdatedAt]    = GETUTCDATE()
WHEN NOT MATCHED THEN INSERT
    ([Code], [Name], [SellerId], [AddressLine1], [AddressLine2], [City], [State], [PinCode], [Country])
VALUES
    (src.[Code], src.[Name], src.[SellerId], src.[AddressLine1], src.[AddressLine2],
     src.[City], src.[State], src.[PinCode], src.[Country]);
GO
