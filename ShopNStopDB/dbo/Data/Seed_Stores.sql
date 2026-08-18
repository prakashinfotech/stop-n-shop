SET IDENTITY_INSERT [dbo].[Stores] ON;

MERGE [dbo].[Stores] AS tgt
USING (VALUES
    (1, N'StopNShop Mumbai — Phoenix Marketcity',
        N'LBS Marg, Kurla West', N'Mumbai', N'Maharashtra', N'400070',
        CAST(19.087130 AS DECIMAL(9,6)), CAST(72.889080 AS DECIMAL(9,6)),
        N'+91 22 4900 0001'),
    (2, N'StopNShop Mumbai — Inorbit Malad',
        N'Link Road, Malad West', N'Mumbai', N'Maharashtra', N'400064',
        CAST(19.184150 AS DECIMAL(9,6)), CAST(72.836050 AS DECIMAL(9,6)),
        N'+91 22 4900 0002'),
    (3, N'StopNShop Delhi — Select Citywalk',
        N'A-3, District Centre, Saket', N'New Delhi', N'Delhi', N'110017',
        CAST(28.528120 AS DECIMAL(9,6)), CAST(77.219810 AS DECIMAL(9,6)),
        N'+91 11 4900 0001'),
    (4, N'StopNShop Bengaluru — Phoenix Marketcity',
        N'Whitefield Main Road, Mahadevapura', N'Bengaluru', N'Karnataka', N'560048',
        CAST(12.997740 AS DECIMAL(9,6)), CAST(77.696200 AS DECIMAL(9,6)),
        N'+91 80 4900 0001'),
    (5, N'StopNShop Pune — Phoenix Marketcity',
        N'Viman Nagar', N'Pune', N'Maharashtra', N'411014',
        CAST(18.561640 AS DECIMAL(9,6)), CAST(73.917500 AS DECIMAL(9,6)),
        N'+91 20 4900 0001'),
    (6, N'StopNShop Hyderabad — Inorbit',
        N'HITEC City', N'Hyderabad', N'Telangana', N'500081',
        CAST(17.434730 AS DECIMAL(9,6)), CAST(78.382900 AS DECIMAL(9,6)),
        N'+91 40 4900 0001')
) AS src ([StoreId], [StoreName], [Address], [City], [State], [Pincode], [Lat], [Lng], [Phone])
ON tgt.[StoreId] = src.[StoreId]
WHEN MATCHED THEN UPDATE SET
    tgt.[StoreName] = src.[StoreName],
    tgt.[Address]   = src.[Address],
    tgt.[City]      = src.[City],
    tgt.[State]     = src.[State],
    tgt.[Pincode]   = src.[Pincode],
    tgt.[Lat]       = src.[Lat],
    tgt.[Lng]       = src.[Lng],
    tgt.[Phone]     = src.[Phone]
WHEN NOT MATCHED THEN INSERT
    ([StoreId], [StoreName], [Address], [City], [State], [Pincode],
     [Lat], [Lng], [Phone], [CreatedAt], [IsActive], [IsDeleted])
VALUES
    (src.[StoreId], src.[StoreName], src.[Address], src.[City], src.[State], src.[Pincode],
     src.[Lat], src.[Lng], src.[Phone], GETUTCDATE(), 1, 0);

SET IDENTITY_INSERT [dbo].[Stores] OFF;

DBCC CHECKIDENT ('[dbo].[Stores]', RESEED, 6);
GO
