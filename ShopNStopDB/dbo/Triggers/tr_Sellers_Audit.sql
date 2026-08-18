CREATE TRIGGER [dbo].[tr_Sellers_Audit]
ON [dbo].[Sellers]
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
        N'Sellers',
        COALESCE(i.[SellerId], d.[SellerId]),
        @Action,
        (SELECT d.[ApprovalStatus], d.[CommissionRate], d.[IsActive], d.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.[ApprovalStatus], i.[CommissionRate], i.[IsActive], i.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.[SellerId] = i.[SellerId];
END;
GO
