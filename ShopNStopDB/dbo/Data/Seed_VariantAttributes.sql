-- Seeds the master attribute list. Idempotent via MERGE on AttributeKey.
MERGE [dbo].[VariantAttributes] AS tgt
USING (VALUES
    (N'size',     N'Size',     N'select', 10),
    (N'color',    N'Color',    N'swatch', 20),
    (N'material', N'Material', N'select', 30),
    (N'pattern',  N'Pattern',  N'select', 40),
    (N'fit',      N'Fit',      N'select', 50)
) AS src ([AttributeKey], [DisplayName], [InputType], [SortOrder])
ON tgt.[AttributeKey] = src.[AttributeKey]
WHEN NOT MATCHED THEN
    INSERT ([AttributeKey], [DisplayName], [InputType], [SortOrder])
    VALUES (src.[AttributeKey], src.[DisplayName], src.[InputType], src.[SortOrder])
WHEN MATCHED THEN UPDATE SET
    [DisplayName] = src.[DisplayName],
    [InputType]   = src.[InputType],
    [SortOrder]   = src.[SortOrder];
GO
