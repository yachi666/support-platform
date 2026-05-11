#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.dev-runtime"
LOG_DIR="$RUNTIME_DIR/logs"
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"
POSTGRES_STARTUP_LOG="$LOG_DIR/postgresql-startup.log"
BACKEND_HEALTH_URL="${BACKEND_HEALTH_URL:-http://127.0.0.1:8080/actuator/health}"
FRONTEND_URL="${FRONTEND_URL:-http://127.0.0.1:5173}"
DB_URL="${DB_URL:-jdbc:postgresql://127.0.0.1:5432/support}"
DB_USERNAME="${DB_USERNAME:-$(id -un 2>/dev/null || printf 'postgres')}"
DB_PASSWORD="${DB_PASSWORD:-123456}"
START_LOCAL_POSTGRES_WITH_BREW="${START_LOCAL_POSTGRES_WITH_BREW:-auto}"
POSTGRES_READY_HOST=""
POSTGRES_READY_PORT=""
POSTGRES_READY_DB_NAME=""
POSTGRES_DATA_DIR=""

log() {
  echo "[restart-all] $*"
}

mkdir -p "$LOG_DIR"

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
  if command -v pg_isready >/dev/null 2>&1; then
    return 0
  fi

  if command -v psql >/dev/null 2>&1; then
    return 0
  fi

  log "Either pg_isready or psql is required to verify PostgreSQL readiness before restarting services."
  return 1
}

postgres_admin_command() {
  env PGPASSWORD="$DB_PASSWORD" "$@"
}

find_local_postgres_data_dir() {
  local brew_prefix
  local candidate
  local versioned_candidate=""

  brew_prefix="${HOMEBREW_PREFIX:-}"
  if [[ -z "$brew_prefix" ]] && command -v brew >/dev/null 2>&1; then
    brew_prefix="$(brew --prefix 2>/dev/null || true)"
  fi

  [[ -n "$brew_prefix" ]] || return 1

  for candidate in "$brew_prefix"/var/postgresql@*; do
    if [[ -f "$candidate/PG_VERSION" ]]; then
      versioned_candidate="$candidate"
    fi
  done

  if [[ -n "$versioned_candidate" ]]; then
    POSTGRES_DATA_DIR="$versioned_candidate"
    return 0
  fi

  candidate="$brew_prefix/var/postgresql"
  if [[ -f "$candidate/PG_VERSION" ]]; then
    POSTGRES_DATA_DIR="$candidate"
    return 0
  fi

  return 1
}

postgres_database_exists_tools_available() {
  if ! command -v psql >/dev/null 2>&1; then
    log "psql is required to verify whether database '$POSTGRES_READY_DB_NAME' exists."
    return 1
  fi
}

postgres_server_is_ready() {
  if command -v pg_isready >/dev/null 2>&1; then
    pg_isready -h "$POSTGRES_READY_HOST" -p "$POSTGRES_READY_PORT" -d postgres -U "$DB_USERNAME" >/dev/null 2>&1
    return $?
  fi

  postgres_admin_command \
    psql -h "$POSTGRES_READY_HOST" -p "$POSTGRES_READY_PORT" -U "$DB_USERNAME" -d postgres -Atqc 'SELECT 1' >/dev/null 2>&1
}

postgres_database_exists() {
  local result

  result="$({ postgres_admin_command \
    psql -h "$POSTGRES_READY_HOST" -p "$POSTGRES_READY_PORT" -U "$DB_USERNAME" -d postgres -Atqc "SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_READY_DB_NAME'"; } 2>/dev/null || true)"

  [[ "$result" == "1" ]]
}

is_local_postgres_target() {
  case "$POSTGRES_READY_HOST" in
    127.0.0.1|localhost|::1)
      return 0
      ;;
  esac

  return 1
}

should_start_local_postgres_with_brew() {
  case "$START_LOCAL_POSTGRES_WITH_BREW" in
    1|true|TRUE|yes|YES)
      return 0
      ;;
    0|false|FALSE|no|NO)
      return 1
      ;;
    auto|AUTO|'')
      is_local_postgres_target
      return $?
      ;;
  esac

  log "START_LOCAL_POSTGRES_WITH_BREW must be one of: auto, 1, 0."
  return 1
}

create_database_if_missing() {
  if ! postgres_database_exists_tools_available; then
    return 1
  fi

  if postgres_database_exists; then
    log "PostgreSQL database '$POSTGRES_READY_DB_NAME' is ready."
    return 0
  fi

  if ! is_local_postgres_target; then
    log "PostgreSQL server is reachable, but database '$POSTGRES_READY_DB_NAME' does not exist on remote host $POSTGRES_READY_HOST."
    return 1
  fi

  if ! command -v createdb >/dev/null 2>&1; then
    log "createdb is required to initialize local database '$POSTGRES_READY_DB_NAME' on first startup."
    return 1
  fi

  log "Database '$POSTGRES_READY_DB_NAME' does not exist; creating it for first startup."
  if ! postgres_admin_command createdb -h "$POSTGRES_READY_HOST" -p "$POSTGRES_READY_PORT" -U "$DB_USERNAME" "$POSTGRES_READY_DB_NAME"; then
    log "Failed to create database '$POSTGRES_READY_DB_NAME'."
    return 1
  fi

  if postgres_database_exists; then
    log "Database '$POSTGRES_READY_DB_NAME' created successfully."
    return 0
  fi

  log "Database '$POSTGRES_READY_DB_NAME' was created but could not be verified."
  return 1
}

start_local_postgres_with_pg_ctl() {
  local postgres_log_path

  if ! is_local_postgres_target; then
    return 1
  fi

  if ! command -v pg_ctl >/dev/null 2>&1; then
    log "pg_ctl is unavailable, so restart-all.sh cannot fall back to direct PostgreSQL startup."
    return 1
  fi

  if ! find_local_postgres_data_dir; then
    log "Could not locate a local Homebrew PostgreSQL data directory for pg_ctl fallback."
    return 1
  fi

  postgres_log_path="$LOG_DIR/postgresql.log"
  log "Falling back to pg_ctl with data dir $POSTGRES_DATA_DIR"
  if ! pg_ctl -D "$POSTGRES_DATA_DIR" -l "$postgres_log_path" start; then
    log "pg_ctl fallback failed to start PostgreSQL."
    return 1
  fi

  if ! wait_for_postgres 45; then
    log "PostgreSQL failed to become ready after pg_ctl fallback startup."
    return 1
  fi

  return 0
}

start_local_postgres_with_brew() {
  : >"$POSTGRES_STARTUP_LOG"

  if brew services start postgresql >"$POSTGRES_STARTUP_LOG" 2>&1; then
    return 0
  fi

  log "Homebrew PostgreSQL service failed to start; detailed output saved to $POSTGRES_STARTUP_LOG"
  return 1
}

wait_for_postgres() {
  local retries="$1"

  log "Waiting for PostgreSQL server at $POSTGRES_READY_HOST:$POSTGRES_READY_PORT"
  for ((attempt = 1; attempt <= retries; attempt++)); do
    if postgres_server_is_ready; then
      log "PostgreSQL server is ready."
      return 0
    fi

    if (( attempt == 1 || attempt % 5 == 0 || attempt == retries )); then
      log "PostgreSQL server not ready yet (attempt $attempt/$retries)."
    fi
    sleep 1
  done

  return 1
}

ensure_postgres_running() {
  if ! postgres_readiness_tools_available; then
    return 1
  fi

  if ! postgres_server_is_ready; then
    if ! should_start_local_postgres_with_brew; then
      log "PostgreSQL server is not ready. Set START_LOCAL_POSTGRES_WITH_BREW=1 to force Homebrew startup, or keep the default auto mode for local databases."
      return 1
    fi

    if ! command -v brew >/dev/null 2>&1; then
      log "Homebrew is unavailable; trying pg_ctl fallback for local PostgreSQL startup."
      if ! start_local_postgres_with_pg_ctl; then
        return 1
      fi
    else
      log "PostgreSQL server is not ready; starting Homebrew PostgreSQL service."
      if start_local_postgres_with_brew; then
        if ! wait_for_postgres 45; then
          log "PostgreSQL failed to become ready after brew startup."
          return 1
        fi
      else
        log "Homebrew failed to start PostgreSQL; trying pg_ctl fallback."
        if ! start_local_postgres_with_pg_ctl; then
          return 1
        fi
      fi
    fi
  else
    log "PostgreSQL server is already ready."
  fi

  create_database_if_missing
}

if ! parse_postgres_ready_target; then
  exit 1
fi

if ! ensure_postgres_running; then
  exit 1
fi

log "Stopping existing services if present."
"$ROOT_DIR/scripts/dev/stop-all.sh"
log "Stop phase completed."

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
