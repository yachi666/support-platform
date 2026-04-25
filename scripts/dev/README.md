# Development Scripts

Run all commands from the repository root.

## Available Commands

### Start backend in the foreground

```bash
./scripts/dev/start-backend.sh
```

Uses these defaults unless overridden in the environment:

- `DB_URL=jdbc:postgresql://127.0.0.1:5432/support`
- `DB_USERNAME=$(id -un)` (falls back to `postgres` if the current user cannot be resolved)
- `DB_PASSWORD=123456`

### Start frontend in the foreground

```bash
./scripts/dev/start-frontend.sh
```

Uses these defaults unless overridden in the environment:

- `HOST=127.0.0.1`
- `PORT=5173`

### Stop both services

```bash
./scripts/dev/stop-all.sh
```

Stops tracked processes and any listeners on ports `8080` and `5173`.
If nothing is running, it still exits successfully and prints what it checked.

### Restart and verify both services

```bash
./scripts/dev/restart-all.sh
```

This is the preferred local development entry point. It:

1. Verifies PostgreSQL readiness using `pg_isready` against the host, port, and database parsed from `DB_URL`
2. Optionally starts Homebrew PostgreSQL if you set `START_LOCAL_POSTGRES_WITH_BREW=1`
3. Stops existing frontend and backend listeners on `5173` and `8080`
4. Restarts both services in the background
5. Waits for `http://127.0.0.1:8080/actuator/health`
6. Waits for `http://127.0.0.1:5173`

When services are restarted in the background, the script explicitly disables proxy
environment variables and bypasses proxies for local health checks.
It also prints progress logs for stopping, starting, and waiting for health checks.

`restart-all.sh` uses these defaults unless overridden in the environment:

- `DB_URL=jdbc:postgresql://127.0.0.1:5432/support`
- `DB_USERNAME=$(id -un)` (falls back to `postgres` if the current user cannot be resolved)
- `START_LOCAL_POSTGRES_WITH_BREW=0`

If PostgreSQL is not ready and `START_LOCAL_POSTGRES_WITH_BREW` is left at `0`,
the script exits with a clear message instead of mutating the local machine state.
Set `START_LOCAL_POSTGRES_WITH_BREW=1` only when you want `restart-all.sh` to run
`brew services start postgresql` on your machine.

`pg_isready` must be available in `PATH` for the readiness check. On macOS with
Homebrew PostgreSQL installed, it is typically available automatically.
If this PostgreSQL preflight fails, `restart-all.sh` exits before stopping the
currently running frontend or backend processes.

Logs are written to:

- `.dev-runtime/logs/backend.log`
- `.dev-runtime/logs/frontend.log`
