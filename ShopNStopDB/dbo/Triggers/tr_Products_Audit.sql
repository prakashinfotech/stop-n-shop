CREATE TRIGGER [dbo].[tr_Products_Audit]
ON [dbo].[Products]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Action NVARCHAR(10) = CASE
        WHEN EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted) THEN N'UPDATE'
        WHEN EXISTS (SELECT 1 FROM inserted) THEN N'INSERT'
        ELSE N'DELETE'
    END;

    INSERT INTO [dbo].[AuditLogs]
        ([TableName], [RecordId], [Action], [OldValues], [NewValues], [ChangedBy], [ChangedAt])
    SELECT
        N'Products',
        COALESCE(i.[ProductId], d.[ProductId]),
        @Action,
        (SELECT d.[ApprovalStatus], d.[IsActive], d.[IsDeleted], d.[MRP], d.[SellingPrice] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.[ApprovalStatus], i.[IsActive], i.[IsDeleted], i.[MRP], i.[SellingPrice] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.[ProductId] = i.[ProductId];
END;
GO
