-- Profile lookup for the dispatcher portal. Includes the assigned warehouses
-- inline as a comma-separated string (small list, no need for a second SP).
CREATE PROCEDURE [dbo].[usp_Dispatcher_GetProfile]
    @UserId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        d.[DispatcherId],
        d.[UserId],
        d.[EmployeeCode],
        d.[VehicleNumber],
        d.[VehicleType],
        d.[LicenseNumber],
        d.[BaseWarehouseId],
        wb.[Name]                   AS [BaseWarehouseName],
        u.[FirstName],
        u.[LastName],
        u.[Email],
        u.[Mobile],
        d.[JoinedAt],
        d.[IsActive],
        STUFF((
            SELECT N', ' + w.[Code] + N' — ' + w.[Name]
            FROM   [dbo].[DispatcherWarehouseAssignments] dwa
            INNER JOIN [dbo].[Warehouses] w ON w.[WarehouseId] = dwa.[WarehouseId]
            WHERE  dwa.[DispatcherId] = d.[DispatcherId] AND w.[IsDeleted] = 0
            ORDER BY w.[Name]
            FOR XML PATH(''), TYPE
        ).value(N'.', N'NVARCHAR(MAX)'), 1, 2, N'')   AS [AssignedWarehousesLabel]
    FROM   [dbo].[Dispatchers]      d
    INNER JOIN [dbo].[Users]        u  ON u.[UserId]      = d.[UserId]
    LEFT  JOIN [dbo].[Warehouses]   wb ON wb.[WarehouseId] = d.[BaseWarehouseId]
    WHERE  d.[UserId]   = @UserId
      AND  d.[IsDeleted] = 0;
END;
GO
