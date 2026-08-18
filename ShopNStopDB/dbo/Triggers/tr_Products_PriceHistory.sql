CREATE TRIGGER [dbo].[tr_Products_PriceHistory]
ON [dbo].[Products]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Only fire when MRP or SellingPrice changes
    IF NOT (UPDATE([MRP]) OR UPDATE([SellingPrice]))
        RETURN;

    INSERT INTO [dbo].[PriceHistory]
        ([ProductId], [OldMRP], [NewMRP], [OldSellingPrice], [NewSellingPrice], [ChangedBy], [ChangedAt], [Reason])
    SELECT
        i.[ProductId],
        d.[MRP],
        i.[MRP],
        d.[SellingPrice],
        i.[SellingPrice],
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE(),
        N'Automatic price change via trigger'
    FROM inserted i
    INNER JOIN deleted d ON d.[ProductId] = i.[ProductId]
    WHERE d.[MRP] <> i.[MRP] OR d.[SellingPrice] <> i.[SellingPrice];
END;
GO
