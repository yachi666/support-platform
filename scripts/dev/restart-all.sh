#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.dev-runtime"
LOG_DIR="$RUNTIME_DIR/logs"
BACKEND_LOG="$LOG_DIR/backend.log"
FRONTEND_LOG="$LOG_DIR/frontend.log"
BACKEND_HEALTH_URL="${BACKEND_HEALTH_URL:-http://127.0.0.1:8080/actuator/health}"
FRONTEND_URL="${FRONTEND_URL:-http://127.0.0.1:5173}"

log() {
  echo "[restart-all] $*"
}

mkdir -p "$LOG_DIR"

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
