# Contributing to StopNShop

Thank you for helping improve StopNShop. This guide explains the expected development and pull-request workflow.

## Before You Start

- Read the project setup instructions in [README.md](README.md).
- Search existing issues and pull requests before starting duplicate work.
- For security vulnerabilities, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.

## Development Setup

Clone your fork and install the project dependencies:

```bash
git clone https://github.com/YOUR_USERNAME/stop-n-shop.git
cd stop-n-shop

cd stopnshop-ui
npm install

cd ../api
dotnet restore
```

Configure local environment values using `.env`, environment variables, or `appsettings.Development.json` / [.NET User Secrets](https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets). Never commit real credentials — only the tracked `.env.example` and `appsettings.Development.json.example` placeholder templates.

## Contribution Workflow

1. Create a branch from the latest `master` branch:

   ```bash
   git checkout master
   git pull origin master
   git checkout -b feat/short-description
   ```

2. Make focused changes that match the existing project architecture and style:
   - **Controller → Service → Repository** — no logic shortcuts between layers.
   - **Stored-procedure-only** data access via Dapper — no inline SQL, no EF Core.
   - `ApiResponse<T>` envelope on every endpoint; paginated list responses.
   - In the UI, consume design tokens and shared primitives — no raw `bg-white` / `bg-gray-*`.
3. Add or update tests when behavior changes.
4. Run the relevant quality checks.
5. Commit using [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`…).
6. Push your branch and open a pull request against `master`.

## Quality Checks

Run the frontend checks:

```bash
cd stopnshop-ui
npm run lint
npm run build
npm run test
npm audit
```

Run the backend checks from the repository root:

```bash
dotnet build StopNShop.sln --configuration Release
dotnet test tests/StopNShop.Api.UnitTests
dotnet test tests/StopNShop.Api.IntegrationTests
dotnet list api/ShopNShop.Api.csproj package --vulnerable --include-transitive
```

## Security and Sensitive Data

Do not commit:

- API keys, tokens, passwords, or connection strings
- `.env` files or production configuration (`appsettings.Development.json`, `appsettings.Production.json`)
- private certificates or SSH keys
- personal data, database exports, or service-account credentials

Use the tracked `.example` files only for safe placeholders. If a secret is committed accidentally, rotate it immediately before requesting history cleanup.

## Pull Request Checklist

- [ ] The change is focused and documented.
- [ ] Tests and builds relevant to the change pass locally.
- [ ] No secret, credential, or private data is included.
- [ ] New configuration variables are documented with safe placeholders.
- [ ] The pull request explains what changed and how it was verified.

By contributing, you agree that your contribution may be used under the repository's applicable license and company policies.
