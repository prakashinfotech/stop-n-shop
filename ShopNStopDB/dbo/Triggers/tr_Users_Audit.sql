CREATE TRIGGER [dbo].[tr_Users_Audit]
ON [dbo].[Users]
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
        N'Users',
        COALESCE(i.[UserId], d.[UserId]),
        @Action,
        (SELECT d.[Email], d.[RoleId], d.[IsApproved], d.[IsActive], d.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        (SELECT i.[Email], i.[RoleId], i.[IsApproved], i.[IsActive], i.[IsDeleted] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        COALESCE(i.[UpdatedBy], i.[CreatedBy]),
        GETUTCDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON d.[UserId] = i.[UserId];
END;
GO
