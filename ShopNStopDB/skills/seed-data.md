Generate a seed data SQL script for a given table.

Rules:
- Use `IF NOT EXISTS` checks before every INSERT to make scripts re-runnable
- Use `SET IDENTITY_INSERT ON/OFF` only when seeding tables with explicit IDs
- Place the file in `ShopNStopDB/dbo/Data/` named `Seed_TableName.sql`
- Include a comment header: table name, purpose, and date
- Keep seed data realistic — use Indian names, INR prices, Indian cities for this project
