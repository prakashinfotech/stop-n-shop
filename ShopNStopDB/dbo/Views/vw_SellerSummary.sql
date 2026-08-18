CREATE VIEW [dbo].[vw_SellerSummary]
AS
SELECT
    s.[SellerId],
    s.[BusinessName],
    s.[GstNumber],
    s.[PanNumber],
    s.[ApprovalStatus],
    s.[CommissionRate],
    s.[IsActive],

    -- User info
    u.[UserId],
    u.[Email],
    u.[FirstName],
    u.[LastName],
    u.[Mobile],
    u.[ProfileImageUrl],

    -- Business address
    ua.[AddressLine1],
    ua.[City],
    ua.[State],
    ua.[PinCode],

    -- Counts
    ISNULL(pc.[ProductCount], 0)          AS [TotalProducts],
    ISNULL(bm.[BrandCount], 0)            AS [ApprovedBrandCount]

FROM [dbo].[Sellers]        s
INNER JOIN [dbo].[Users]          u   ON u.[UserId]    = s.[UserId]            AND u.[IsDeleted]  = 0
LEFT  JOIN [dbo].[UserAddresses]  ua  ON ua.[AddressId] = s.[BusinessAddressId]
LEFT  JOIN (
    SELECT [SellerId], COUNT([ProductId]) AS [ProductCount]
    FROM [dbo].[Products]
    WHERE [IsDeleted] = 0 AND [ApprovalStatus] = 2
    GROUP BY [SellerId]
) pc ON pc.[SellerId] = s.[SellerId]
LEFT  JOIN (
    SELECT [SellerId], COUNT([MappingId]) AS [BrandCount]
    FROM [dbo].[SellerBrandMappings]
    WHERE [IsDeleted] = 0 AND [IsApproved] = 1
    GROUP BY [SellerId]
) bm ON bm.[SellerId] = s.[SellerId]

WHERE s.[IsDeleted] = 0;
GO
