# Development Scripts

[中文](./README.zh-CN.md)

Local orchestration scripts for the support roster workspace. Run all commands from the repository root unless a script explicitly says otherwise.

## Command Overview

| Command | Purpose |
|---------|---------|
| `./scripts/dev/start-backend.sh` | Start `support-roster-server` in the foreground. |
| `./scripts/dev/start-frontend.sh` | Start `support-roster-ui` in the foreground. |
| `./scripts/dev/stop-all.sh` | Stop tracked services and listeners on the default ports. |
| `./scripts/dev/restart-all.sh` | Restart backend and frontend in the background, then wait for health checks. |
| `./scripts/dev/init-admin.sh` | Initialize the first local admin account and assign it to a valid bootstrap team. |
| `./scripts/dev/test-restart-all.sh` | Exercise the restart script behavior. |

## Recommended Entry Point

```bash
./scripts/dev/restart-all.sh
```

`restart-all.sh` is the preferred local development entry point. It:

1. Parses `DB_URL` and verifies PostgreSQL server readiness with `pg_isready` or `psql`.
2. Auto-starts local Homebrew PostgreSQL by default when the target host is local and the server is down.
3. Auto-creates the local target database on first startup when it does not exist yet.
4. Stops existing listeners on ports `8080` and `5173`.
5. Starts backend and frontend in the background.
6. Waits for `http://127.0.0.1:8080/actuator/health`.
7. Waits for `http://127.0.0.1:5173`.
8. Writes runtime logs under `.dev-runtime/logs/`.

## Defaults

| Variable | Used By | Default |
|----------|---------|---------|
| `DB_URL` | Backend and restart preflight | `jdbc:postgresql://127.0.0.1:5432/support` |
| `DB_USERNAME` | Backend and PostgreSQL readiness | current system user, with script-specific fallback |
| `DB_PASSWORD` | Backend | `123456` |
| `HOST` | Frontend | `127.0.0.1` |
| `PORT` | Frontend | `5173` |
| `BACKEND_HEALTH_URL` | Restart health check | `http://127.0.0.1:8080/actuator/health` |
| `FRONTEND_URL` | Restart health check | `http://127.0.0.1:5173` |
| `START_LOCAL_POSTGRES_WITH_BREW` | Restart preflight | `auto` |

## Individual Commands

### Start Backend

```bash
./scripts/dev/start-backend.sh
```

Starts the Spring Boot service in the foreground. Use this when you want backend logs directly in the terminal.

### Start Frontend

```bash
./scripts/dev/start-frontend.sh
```

Starts the Vite development server in the foreground.

### Stop Services

```bash
./scripts/dev/stop-all.sh
```

Stops tracked background processes and any listeners on ports `8080` and `5173`. It exits successfully even when nothing is running.

### Restart Services

```bash
./scripts/dev/restart-all.sh
```

Starts both services in the background with local proxy variables disabled for health checks. Logs are written to:

```text
.dev-runtime/logs/backend.log
.dev-runtime/logs/frontend.log
```

### Initialize First Admin

```bash
./scripts/dev/init-admin.sh
```

Creates or updates a reusable local bootstrap admin with these defaults:

- staff ID: `admin`
- password: `admin`
- team: `System Admin`

The script keeps the admin attached to a valid team so validation smoke tests do not pick up an unrelated `Missing Team` issue on a fresh database.

Common overrides:

```bash
ADMIN_STAFF_ID=alice \
ADMIN_PASSWORD=secret123 \
ADMIN_TEAM_NAME="Workspace Admin" \
./scripts/dev/init-admin.sh
```

## PostgreSQL Preflight

`restart-all.sh` exits before stopping existing services if PostgreSQL cannot be started or verified. This protects a working frontend/backend session from being torn down when the database is unavailable.

Requirements:

- `DB_URL` must use `jdbc:postgresql://host[:port]/database`.
- Either `pg_isready` or `psql` must be available in `PATH`.
- `psql` and `createdb` are required to auto-create the local database on first startup.
- `START_LOCAL_POSTGRES_WITH_BREW=auto` is the default and only auto-starts Homebrew PostgreSQL for local database targets. Set it to `0` to disable automatic startup, or `1` to force Homebrew startup.

## Example

```bash
DB_URL=jdbc:postgresql://127.0.0.1:5432/support \
DB_USERNAME="$(id -un)" \
DB_PASSWORD=123456 \
./scripts/dev/restart-all.sh
```

After a successful restart:

```text
Frontend: http://127.0.0.1:5173
Backend health: http://127.0.0.1:8080/actuator/health
Backend log: .dev-runtime/logs/backend.log
Frontend log: .dev-runtime/logs/frontend.log
```
