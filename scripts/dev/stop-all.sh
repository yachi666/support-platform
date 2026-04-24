#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNTIME_DIR="$ROOT_DIR/.dev-runtime"

log() {
  echo "[stop-all] $*"
}

kill_pidfile() {
  local name="$1"
  local pid_file="$2"

  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file")"

    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      log "Stopping $name process from pid file: $pid"
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      log "$name process stopped: $pid"
    else
      log "Found stale $name pid file; removing: $pid_file"
    fi

    rm -f "$pid_file"
  else
    log "No $name pid file found."
  fi
}

kill_port_listener() {
  local name="$1"
  local port="$2"
  local pids

  pids="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    log "Stopping $name listener(s) on port $port: $(tr '\n' ' ' <<< "$pids" | xargs)"
    while IFS= read -r pid; do
      [[ -n "$pid" ]] || continue
      kill "$pid" 2>/dev/null || true
    done <<< "$pids"
    log "$name listener stop signal sent on port $port."
  else
    log "No $name listener found on port $port."
  fi
}

log "Starting shutdown sequence."

kill_pidfile "backend" "$RUNTIME_DIR/backend.pid"
kill_pidfile "frontend" "$RUNTIME_DIR/frontend.pid"

kill_port_listener "backend" 8080
kill_port_listener "frontend" 5173

log "Shutdown sequence completed."
