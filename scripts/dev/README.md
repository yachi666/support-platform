# Development Scripts

Run all commands from the repository root.

## Available Commands

### Start backend in the foreground

```bash
./scripts/dev/start-backend.sh
```

Uses these defaults unless overridden in the environment:

- `DB_URL=jdbc:postgresql://127.0.0.1:5432/support`
- `DB_USERNAME=lzn`
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

1. Stops existing frontend and backend listeners on `5173` and `8080`
2. Restarts both services in the background
3. Waits for `http://127.0.0.1:8080/actuator/health`
4. Waits for `http://127.0.0.1:5173`

When services are restarted in the background, the script explicitly disables proxy
environment variables and bypasses proxies for local health checks.
It also prints progress logs for stopping, starting, and waiting for health checks.

Logs are written to:

- `.dev-runtime/logs/backend.log`
- `.dev-runtime/logs/frontend.log`
