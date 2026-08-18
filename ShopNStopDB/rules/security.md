## DB Security Rules

- Never build SQL strings by concatenating user input — always use parameters
- If dynamic SQL is absolutely necessary, use `sp_executesql` with typed parameters only
- Never return password hashes, tokens, or OTP values in SELECT result sets returned to the API
- Stored procedures are the only permitted data access method — no ad-hoc queries from the API layer
- All audit-sensitive tables (Users, Orders, Products, Sellers) must have audit triggers
