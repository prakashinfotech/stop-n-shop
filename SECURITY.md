# Security Policy

## Supported Version

Security fixes are applied to the latest code on the `master` branch. Older commits and external forks are not actively supported.

## Reporting a Vulnerability

Please do not report suspected vulnerabilities through a public GitHub issue, discussion, or pull request.

Use one of these private channels:

1. Submit a [private GitHub security advisory](https://github.com/prakashinfotech/stop-n-shop/security/advisories/new), if private vulnerability reporting is enabled.
2. Otherwise, email [info@prakashinfotech.com](mailto:info@prakashinfotech.com) with the subject **StopNShop Security Report**.

Include as much of the following information as possible:

- affected component, endpoint, or file
- steps required to reproduce the issue
- expected and observed behavior
- potential impact
- proof-of-concept details with sensitive values removed
- any suggested mitigation

The maintainers will review the report, validate its impact, and coordinate remediation and disclosure when appropriate.

## Handling Secrets

Never include real API keys, passwords, tokens, certificates, deployment hooks, or database credentials in an issue or pull request. If a credential may have been exposed, revoke or rotate it immediately; removing it from the latest commit is not sufficient.

Secrets in this project are injected at runtime via environment variables (`SA_PASSWORD`, `JWT_SECRET_KEY`, `Twilio__*`, `Smtp__*`). Only `.env.example` and `appsettings.Development.json.example` placeholder templates are committed — `.env` and `appsettings.Development.json` are git-ignored.

## Deployment Responsibility

This repository is provided as a project showcase and local-development codebase. Teams deploying it are responsible for configuring production secrets, HTTPS, trusted origins, database access controls, monitoring, backups, and platform-specific security settings.
