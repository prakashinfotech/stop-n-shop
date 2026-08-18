Review the stored procedure provided. Check for:

1. **Naming** — follows `usp_Module_Entity_Action` pattern
2. **Performance** — no SELECT *, uses indexes, avoids cursors, uses EXISTS over COUNT
3. **Security** — no dynamic SQL with string concatenation, all inputs parameterised
4. **Standards** — SET NOCOUNT ON present, schema-qualified (`dbo.`), proper NULL handling
5. **Error handling** — uses TRY/CATCH, rolls back transactions on error
6. **Output** — returns consistent result sets or OUTPUT parameters

Report issues by severity: Critical / Warning / Suggestion.
