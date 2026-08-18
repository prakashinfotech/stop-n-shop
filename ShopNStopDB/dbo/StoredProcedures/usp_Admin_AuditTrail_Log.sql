-- Append-only write into AuditLogs from admin actions.
-- Action is constrained to INSERT/UPDATE/DELETE by CK on AuditLogs; the
-- richer verb (APPROVE, REJECT, SUSPEND, FORCE_CANCEL, REFUND, ...) is
-- embedded in @NewValues as a JSON envelope: { "verb": "...", "data": {...} }.
CREATE PROCEDURE [dbo].[usp_Admin_AuditTrail_Log]
    @TableName  NVARCHAR(100),
    @RecordId   INT,
    @Action     NVARCHAR(10),
    @OldValues  NVARCHAR(MAX) = NULL,
    @NewValues  NVARCHAR(MAX) = NULL,
    @ChangedBy  INT           = NULL,
    @IpAddress  NVARCHAR(50)  = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    INSERT INTO [dbo].[AuditLogs]
        ([TableName], [RecordId], [Action], [OldValues], [NewValues], [ChangedBy], [IpAddress])
    VALUES
        (@TableName, @RecordId, @Action, @OldValues, @NewValues, @ChangedBy, @IpAddress);

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS [AuditId];
END;
GO
