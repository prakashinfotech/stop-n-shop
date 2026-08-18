CREATE FUNCTION [dbo].[fn_GenerateSlug]
(
    @InputText NVARCHAR(400)
)
RETURNS NVARCHAR(400)
WITH SCHEMABINDING
AS
BEGIN
    -- Convert to lower-case, replace spaces/special chars with hyphens
    DECLARE @Slug NVARCHAR(400) = LOWER(@InputText);

    -- Replace common special chars with hyphen
    SET @Slug = REPLACE(@Slug, N' ',  N'-');
    SET @Slug = REPLACE(@Slug, N'/',  N'-');
    SET @Slug = REPLACE(@Slug, N'&',  N'and');
    SET @Slug = REPLACE(@Slug, N'''', N'');
    SET @Slug = REPLACE(@Slug, N'"',  N'');
    SET @Slug = REPLACE(@Slug, N',',  N'');
    SET @Slug = REPLACE(@Slug, N'.',  N'');
    SET @Slug = REPLACE(@Slug, N'(',  N'');
    SET @Slug = REPLACE(@Slug, N')',  N'');

    -- Collapse consecutive hyphens
    WHILE CHARINDEX(N'--', @Slug) > 0
        SET @Slug = REPLACE(@Slug, N'--', N'-');

    -- Trim leading/trailing hyphens
    SET @Slug = LTRIM(RTRIM(@Slug));
    IF LEFT(@Slug,  1) = N'-' SET @Slug = RIGHT(@Slug, LEN(@Slug) - 1);
    IF RIGHT(@Slug, 1) = N'-' SET @Slug = LEFT(@Slug,  LEN(@Slug) - 1);

    RETURN @Slug;
END;
GO
