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
| `./scripts/dev/test-restart-all.sh` | Exercise the restart script behavior. |

## Recommended Entry Point

```bash
./scripts/dev/restart-all.sh
```

`restart-all.sh` is the preferred local development entry point. It:

1. Parses `DB_URL` and verifies PostgreSQL readiness with `pg_isready`.
2. Optionally starts Homebrew PostgreSQL when `START_LOCAL_POSTGRES_WITH_BREW=1`.
3. Stops existing listeners on ports `8080` and `5173`.
4. Starts backend and frontend in the background.
5. Waits for `http://127.0.0.1:8080/actuator/health`.
6. Waits for `http://127.0.0.1:5173`.
7. Writes runtime logs under `.dev-runtime/logs/`.

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
| `START_LOCAL_POSTGRES_WITH_BREW` | Restart preflight | `0` |

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

## PostgreSQL Preflight

`restart-all.sh` exits before stopping existing services if PostgreSQL is not ready. This protects a working frontend/backend session from being torn down when the database is unavailable.

Requirements:

- `DB_URL` must use `jdbc:postgresql://host[:port]/database`.
- `pg_isready` must be available in `PATH`.
- Set `START_LOCAL_POSTGRES_WITH_BREW=1` only when you want the script to run `brew services start postgresql`.

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
