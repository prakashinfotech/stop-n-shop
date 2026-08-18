-- Onboards a Dispatcher. Two paths:
--   (a) Existing user (RoleId already 4) → just upsert Dispatchers row + warehouse assignments
--   (b) New user — caller must have already created the User row with RoleId=4 + PasswordHash
--       (mirrors how Sellers are created via the existing signup flow).
--
-- This SP only manages the Dispatchers profile + warehouse assignments. Pass
-- @WarehouseIdsCsv as e.g. '1,3,5' to assign multiple warehouses in one call.
CREATE PROCEDURE [dbo].[usp_Dispatcher_Register]
    @UserId           INT,
    @EmployeeCode     NVARCHAR(20),
    @VehicleNumber    NVARCHAR(20)   = NULL,
    @VehicleType      NVARCHAR(20)   = NULL,
    @LicenseNumber    NVARCHAR(30)   = NULL,
    @BaseWarehouseId  INT            = NULL,
    @WarehouseIdsCsv  NVARCHAR(MAX)  = NULL,   -- comma-separated warehouse ids
    @CreatedBy        INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- User must exist and carry the Dispatcher role
        IF NOT EXISTS (
            SELECT 1 FROM [dbo].[Users] u
            WHERE u.[UserId] = @UserId AND u.[IsDeleted] = 0 AND u.[RoleId] = 4
        )
            THROW 50400, N'User not found or not a Dispatcher.', 1;

        IF EXISTS (
            SELECT 1 FROM [dbo].[Dispatchers]
            WHERE [EmployeeCode] = @EmployeeCode AND [IsDeleted] = 0
              AND [UserId] <> @UserId
        )
            THROW 50401, N'EmployeeCode already in use by another dispatcher.', 1;

        BEGIN TRANSACTION;

            DECLARE @DispatcherId INT;
            SELECT @DispatcherId = [DispatcherId]
            FROM   [dbo].[Dispatchers]
            WHERE  [UserId] = @UserId AND [IsDeleted] = 0;

            IF @DispatcherId IS NULL
            BEGIN
                INSERT INTO [dbo].[Dispatchers]
                    ([UserId], [EmployeeCode], [VehicleNumber], [VehicleType],
                     [LicenseNumber], [BaseWarehouseId], [CreatedBy], [UpdatedBy])
                VALUES
                    (@UserId, @EmployeeCode, @VehicleNumber, @VehicleType,
                     @LicenseNumber, @BaseWarehouseId, @CreatedBy, @CreatedBy);
                SET @DispatcherId = SCOPE_IDENTITY();
            END
            ELSE
            BEGIN
                UPDATE [dbo].[Dispatchers]
                SET    [EmployeeCode]    = @EmployeeCode,
                       [VehicleNumber]   = @VehicleNumber,
                       [VehicleType]     = @VehicleType,
                       [LicenseNumber]   = @LicenseNumber,
                       [BaseWarehouseId] = @BaseWarehouseId,
                       [UpdatedAt]       = GETUTCDATE(),
                       [UpdatedBy]       = @CreatedBy
                WHERE  [DispatcherId] = @DispatcherId;
            END

            -- Warehouse assignments — replace-all semantics (idempotent for admin re-saves).
            IF @WarehouseIdsCsv IS NOT NULL
            BEGIN
                DELETE FROM [dbo].[DispatcherWarehouseAssignments]
                WHERE [DispatcherId] = @DispatcherId;

                INSERT INTO [dbo].[DispatcherWarehouseAssignments]
                    ([DispatcherId], [WarehouseId], [AssignedBy])
                SELECT @DispatcherId, CAST(LTRIM(RTRIM(value)) AS INT), @CreatedBy
                FROM   STRING_SPLIT(@WarehouseIdsCsv, ',')
                WHERE  LTRIM(RTRIM(value)) <> N''
                  AND  EXISTS (SELECT 1 FROM [dbo].[Warehouses] w
                               WHERE w.[WarehouseId] = CAST(LTRIM(RTRIM(value)) AS INT)
                                 AND w.[IsDeleted] = 0);
            END

        COMMIT TRANSACTION;

        SELECT [DispatcherId], [UserId], [EmployeeCode], [VehicleNumber],
               [VehicleType], [LicenseNumber], [BaseWarehouseId], [CreatedAt]
        FROM   [dbo].[Dispatchers]
        WHERE  [DispatcherId] = @DispatcherId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
