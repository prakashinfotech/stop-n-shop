-- Direct write to the movement ledger. Use only for cases not covered by the
-- adjust/reserve/release/transfer SPs (e.g. opening-balance imports).
CREATE PROCEDURE [dbo].[usp_Inventory_Movement_Log]
    @VariantId     INT,
    @WarehouseId   INT,
    @MovementType  TINYINT,
    @QuantityDelta INT,
    @ReservedDelta INT          = 0,
    @Reason        NVARCHAR(500) = NULL,
    @ReferenceType NVARCHAR(50)  = NULL,
    @ReferenceId   BIGINT        = NULL,
    @ChangedBy     INT           = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [dbo].[StockMovements]
        ([VariantId], [WarehouseId], [MovementType], [QuantityDelta], [ReservedDelta],
         [Reason], [ReferenceType], [ReferenceId], [ChangedBy])
    VALUES
        (@VariantId, @WarehouseId, @MovementType, @QuantityDelta, @ReservedDelta,
         @Reason, @ReferenceType, @ReferenceId, @ChangedBy);

    SELECT SCOPE_IDENTITY() AS [MovementId];
END;
GO
