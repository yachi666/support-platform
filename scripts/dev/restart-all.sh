#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.dev-runtime"
LOG_DIR="$RUNTIME_DIR/logs"
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"
BACKEND_HEALTH_URL="${BACKEND_HEALTH_URL:-http://127.0.0.1:8080/actuator/health}"
FRONTEND_URL="${FRONTEND_URL:-http://127.0.0.1:5173}"
DB_URL="${DB_URL:-jdbc:postgresql://127.0.0.1:5432/support}"
DB_USERNAME="${DB_USERNAME:-lzn}"
START_LOCAL_POSTGRES_WITH_BREW="${START_LOCAL_POSTGRES_WITH_BREW:-0}"
POSTGRES_READY_HOST=""
POSTGRES_READY_PORT=""
POSTGRES_READY_DB_NAME=""

log() {
  echo "[restart-all] $*"
}

mkdir -p "$LOG_DIR"

log "Stopping existing services if present."
"$ROOT_DIR/scripts/dev/stop-all.sh"
log "Stop phase completed."

parse_postgres_ready_target() {
  local normalized_url
  local authority
  local database_name

  normalized_url="${DB_URL#jdbc:postgresql://}"
  if [[ "$normalized_url" == "$DB_URL" ]]; then
    log "DB_URL must use jdbc:postgresql://host[:port]/database format."
    return 1
  fi

  normalized_url="${normalized_url%%\?*}"
  authority="${normalized_url%%/*}"
  database_name="${normalized_url#*/}"

  if [[ -z "$authority" || -z "$database_name" || "$database_name" == "$normalized_url" ]]; then
    log "DB_URL must include both a PostgreSQL host and database name."
    return 1
  fi

  POSTGRES_READY_HOST="${authority%%:*}"
  POSTGRES_READY_PORT="5432"
  if [[ "$authority" == *:* ]]; then
    POSTGRES_READY_PORT="${authority##*:}"
  fi
  POSTGRES_READY_DB_NAME="$database_name"
}

postgres_readiness_tools_available() {
  if ! command -v pg_isready >/dev/null 2>&1; then
    log "pg_isready is required to verify PostgreSQL readiness before restarting services."
    return 1
  fi
}

postgres_is_ready() {
  pg_isready -h "$POSTGRES_READY_HOST" -p "$POSTGRES_READY_PORT" -d "$POSTGRES_READY_DB_NAME" -U "$DB_USERNAME" >/dev/null 2>&1
}

wait_for_postgres() {
  local retries="$1"

  log "Waiting for PostgreSQL at $POSTGRES_READY_HOST:$POSTGRES_READY_PORT/$POSTGRES_READY_DB_NAME"
  for ((attempt = 1; attempt <= retries; attempt++)); do
    if postgres_is_ready; then
      log "PostgreSQL is ready."
      return 0
    fi

    if (( attempt == 1 || attempt % 5 == 0 || attempt == retries )); then
      log "PostgreSQL not ready yet (attempt $attempt/$retries)."
    fi
    sleep 1
  done

  return 1
}

ensure_postgres_running() {
  if ! postgres_readiness_tools_available; then
    return 1
  fi

  if postgres_is_ready; then
    log "PostgreSQL is already ready."
    return 0
  fi

  if [[ "$START_LOCAL_POSTGRES_WITH_BREW" != "1" ]]; then
    log "PostgreSQL is not ready. Set START_LOCAL_POSTGRES_WITH_BREW=1 to allow restart-all.sh to start Homebrew PostgreSQL automatically."
    return 1
  fi

  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew is unavailable, so restart-all.sh cannot start PostgreSQL automatically."
    return 1
  fi

  log "PostgreSQL is not ready; starting Homebrew PostgreSQL service."
  if ! brew services start postgresql; then
    log "Homebrew failed to start PostgreSQL."
    return 1
  fi

  if ! wait_for_postgres 45; then
    log "PostgreSQL failed to become ready after brew startup."
    return 1
  fi
}

if ! parse_postgres_ready_target; then
  exit 1
fi

if ! ensure_postgres_running; then
  exit 1
fi

start_in_background_without_proxy() {
  local script_path="$1"
  local log_path="$2"

  nohup env \
    -u http_proxy \
    -u https_proxy \
    -u all_proxy \
    -u no_proxy \
    -u ftp_proxy \
    -u rsync_proxy \
    -u HTTP_PROXY \
    -u HTTPS_PROXY \
    -u ALL_PROXY \
    -u NO_PROXY \
    -u FTP_PROXY \
    -u RSYNC_PROXY \
    -u JAVA_TOOL_OPTIONS \
    -u JDK_JAVA_OPTIONS \
    -u _JAVA_OPTIONS \
    -u MAVEN_OPTS \
    -u GRADLE_OPTS \
    -u npm_config_proxy \
    -u npm_config_https_proxy \
    -u npm_config_noproxy \
    -u NPM_CONFIG_PROXY \
    -u NPM_CONFIG_HTTPS_PROXY \
    -u NPM_CONFIG_NOPROXY \
    NO_PROXY='*' \
    no_proxy='*' \
    "$script_path" >"$log_path" 2>&1 &

  echo "$!"
}

log "Starting backend."
BACKEND_PID="$(start_in_background_without_proxy "$ROOT_DIR/scripts/dev/start-backend.sh" "$BACKEND_LOG")"
echo "$BACKEND_PID" > "$RUNTIME_DIR/backend.pid"
log "Started backend in background with pid $BACKEND_PID; log: $BACKEND_LOG"

log "Starting frontend."
FRONTEND_PID="$(start_in_background_without_proxy "$ROOT_DIR/scripts/dev/start-frontend.sh" "$FRONTEND_LOG")"
echo "$FRONTEND_PID" > "$RUNTIME_DIR/frontend.pid"
log "Started frontend in background with pid $FRONTEND_PID; log: $FRONTEND_LOG"

wait_for_url() {
  local name="$1"
  local url="$2"
  local retries="$3"

  log "Waiting for $name: $url"
  for ((attempt = 1; attempt <= retries; attempt++)); do
    if curl --noproxy '*' -fsS "$url" >/dev/null 2>&1; then
      log "$name is ready: $url"
      return 0
    fi

    if (( attempt == 1 || attempt % 5 == 0 || attempt == retries )); then
      log "$name not ready yet (attempt $attempt/$retries)."
    fi
    sleep 1
  done

  return 1
}

if ! wait_for_url "Backend" "$BACKEND_HEALTH_URL" 90; then
  log "Backend failed to become healthy. Recent log output:"
  tail -n 40 "$BACKEND_LOG" || true
  exit 1
fi

if ! wait_for_url "Frontend" "$FRONTEND_URL" 45; then
  log "Frontend failed to become ready. Recent log output:"
  tail -n 40 "$FRONTEND_LOG" || true
  exit 1
fi

cat <<EOF
Development services restarted successfully.

Frontend: $FRONTEND_URL
Backend health: $BACKEND_HEALTH_URL
Backend log: $BACKEND_LOG
Frontend log: $FRONTEND_LOG
EOF
