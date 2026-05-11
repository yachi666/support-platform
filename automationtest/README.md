# Automation Test

[中文](./README.zh-CN.md)

Reusable Playwright automation for the support roster platform. This project lives in the parent workspace so browser coverage can exercise `support-roster-ui`, `support-roster-server`, and local development scripts together without adding one-off test scripts inside either submodule.

## Coverage

| Area | What It Checks |
|------|----------------|
| Authentication | Login smoke, account activation assumptions, and protected-route redirects. |
| Workspace smoke | Core workspace pages load for an authenticated user. |
| Permissions | Admin-only navigation and route access checks. |
| Contact information | Public list/search and admin create flows. |
| Validation regressions | Missing primary coverage, bulk actions, exact jump navigation, cleanup confirmation, and validation recompute flows. |
| Workspace export / viewer | Export workbook shape, shift-definition overflow behavior, and visible non-primary viewer shifts. |
| Linux passwords | Protected route guard and smoke coverage for the Linux password page. |
| Roster regressions | Browser coverage for roster planning behavior. |

## Directory Guide

```text
automationtest/
├── config/       # Environment loading and Playwright project config
├── fixtures/     # Shared Playwright fixtures
├── helpers/      # Auth, API clients, DB helpers, seed contracts, cleanup registry
├── pages/        # Page Object Models
├── scripts/      # Precheck scripts
├── specs/        # Test specs
└── artifacts/    # Reports and run output
```

## Prerequisites

- Node.js `^20.19.0 || >=22.12.0`
- npm
- Playwright browser binaries
- Local backend and frontend dependencies
- PostgreSQL when running DB-backed regression seeds

Install dependencies and Chromium:

```bash
cd automationtest
npm install
npm run install:browsers
```

For a brand-new local database, initialize the first admin before authenticated smoke tests:

```bash
./scripts/dev/init-admin.sh
```

The default bootstrap credential is `admin` / `admin` and is attached to a valid team so validation specs start from a clean baseline.

## Environment

Copy `.env.example` to `.env` and adjust values when needed.

| Variable | Default | Purpose |
|----------|---------|---------|
| `AUTOTEST_BASE_URL` | `http://127.0.0.1:5173` | Frontend URL. |
| `AUTOTEST_API_BASE_URL` | `http://127.0.0.1:8080/api` | Backend API base URL. |
| `AUTOTEST_DB_URL` | `postgresql://localhost:5432/support` | PostgreSQL URL for DB-backed seeds. |
| `AUTOTEST_DEFAULT_TIMEOUT_MS` | `15000` | Shared Playwright timeout. |
| `AUTOTEST_TRACE` | `retain-on-failure` | Playwright trace policy. |
| `AUTOTEST_WORKERS` | `1` | Worker count for stable local runs. |
| `AUTOTEST_STAFF_ID` | empty in code, example uses `123456` | Primary smoke-test staff ID. |
| `AUTOTEST_PASSWORD` | empty in code, example uses `12345678` | Primary smoke-test password. |

Optional role-specific credentials are available for permission matrix growth:

```text
AUTOTEST_ADMIN_STAFF_ID
AUTOTEST_ADMIN_PASSWORD
AUTOTEST_EDITOR_STAFF_ID
AUTOTEST_EDITOR_PASSWORD
AUTOTEST_READONLY_STAFF_ID
AUTOTEST_READONLY_PASSWORD
```

## Running Tests

The default entries restart local services through `../scripts/dev/restart-all.sh`, run the precheck, and then execute Playwright.

```bash
npm run test
npm run test:smoke
npm run test:validation
```

Use raw entries when services are already running and you intentionally want to skip the restart step:

```bash
npm run test:raw
npm run test:smoke:raw
npm run test:validation:raw
```

Interactive and debugging commands:

```bash
npm run test:headed
npm run test:ui
npm run codegen
```

Manual viewer data seeding:

```bash
npm run seed:viewer-month
npm run cleanup:viewer-month
```

`seed:viewer-month` creates a dense current-month roster for the public viewer through workspace APIs and stores the latest cleanup manifest at `artifacts/manual-seeds/viewer-current-month-latest.json`.

## Current Specs

```text
specs/auth/linux-password-route-guard.spec.mjs
specs/auth/login-smoke.spec.mjs
specs/auth/route-guard.spec.mjs
specs/contact-information/admin-create.spec.mjs
specs/contact-information/public-list.spec.mjs
specs/permissions/admin-route-access.spec.mjs
specs/workspace/core-smoke.spec.mjs
specs/workspace/export-shift-viewer-regression.spec.mjs
specs/workspace/linux-passwords-smoke.spec.mjs
specs/workspace/roster-regression.spec.mjs
specs/workspace/validation-cleanup-regression.spec.mjs
specs/workspace/validation-regression.spec.mjs
```

## Data Lifecycle

The project prefers reusable manual test environments, but regression specs can create isolated data when a scenario would otherwise be unstable.

Two helper layers keep this controlled:

| Helper | Role |
|--------|------|
| `helpers/seed-contracts.mjs` | Describes required test data and creates scenario-specific records when needed. |
| `helpers/cleanup-registry.mjs` | Registers cleanup steps so API-created and DB-created records are removed after each test. |

Guidance:

- Prefer public or workspace APIs for legal, user-reachable data states.
- Use direct PostgreSQL seeding only for corruption regressions that normal APIs cannot create reliably.
- Add cleanup registration at the same time as any seed creation.
- For manual local viewer population, use `npm run seed:viewer-month`; it creates visible teams, staff, and shared shift definitions for every day of the current month and records cleanup IDs in `artifacts/manual-seeds/`.

## Troubleshooting

- Run `npm run precheck` first when environment setup is uncertain.
- Use `npm run test:raw` only after confirming the frontend and backend are already available.
- Check `.dev-runtime/logs/backend.log` and `.dev-runtime/logs/frontend.log` when default commands fail during service startup.
- Keep new browser tests in this project rather than scattering temporary Playwright scripts across the UI or server submodules.

## License

This project is private workspace tooling. Package metadata currently declares `MIT`.
