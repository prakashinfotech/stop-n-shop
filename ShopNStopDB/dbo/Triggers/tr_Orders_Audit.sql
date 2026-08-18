CREATE TRIGGER [dbo].[tr_Orders_Audit]
ON [dbo].[Orders]
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
        N'Orders',
        COALESCE(i.[OrderId], d.[OrderId]),
        @Action,
        (SELECT d.[OrderStatus], d.[PaymentStatus], d.[TotalAmount], d.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.[OrderStatus], i.[PaymentStatus], i.[TotalAmount], i.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.[OrderId] = i.[OrderId];
END;
GO
