#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/scripts/dev/restart-all.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_file_contains() {
  local file_path="$1"
  local expected="$2"

  grep -F "$expected" "$file_path" >/dev/null 2>&1 || fail "Expected '$expected' in $file_path"
}

assert_file_empty() {
  local file_path="$1"

  [[ ! -s "$file_path" ]] || fail "Expected $file_path to be empty"
}

wait_for_file_contains() {
  local file_path="$1"
  local expected="$2"

  for _ in {1..50}; do
    if grep -F "$expected" "$file_path" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done

  fail "Expected '$expected' in $file_path"
}

setup_fake_repo() {
  local sandbox_root="$1"

  mkdir -p "$sandbox_root/scripts/dev" "$sandbox_root/bin"
  cp "$SCRIPT_UNDER_TEST" "$sandbox_root/scripts/dev/restart-all.sh"
  chmod +x "$sandbox_root/scripts/dev/restart-all.sh"

  cat >"$sandbox_root/scripts/dev/stop-all.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo stop >>"${TRACE_LOG:?}"
EOF
  chmod +x "$sandbox_root/scripts/dev/stop-all.sh"

  cat >"$sandbox_root/scripts/dev/start-backend.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo backend >>"${TRACE_LOG:?}"
EOF
  chmod +x "$sandbox_root/scripts/dev/start-backend.sh"

  cat >"$sandbox_root/scripts/dev/start-frontend.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo frontend >>"${TRACE_LOG:?}"
EOF
  chmod +x "$sandbox_root/scripts/dev/start-frontend.sh"

  cat >"$sandbox_root/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF
  chmod +x "$sandbox_root/bin/curl"

  cat >"$sandbox_root/bin/sleep" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exit 0
EOF
  chmod +x "$sandbox_root/bin/sleep"

  cat >"$sandbox_root/bin/pg_isready" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ -f "${DB_READY_FILE:?}" ]]; then
  exit 0
fi
exit 1
EOF
  chmod +x "$sandbox_root/bin/pg_isready"

  cat >"$sandbox_root/bin/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"${BREW_LOG:?}"
if [[ "$*" == "services start postgresql" ]]; then
  : >"${DB_READY_FILE:?}"
fi
EOF
  chmod +x "$sandbox_root/bin/brew"
}

run_case() {
  local case_name="$1"
  local db_initial_state="$2"
  local expectation="$3"
  local sandbox_root

  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local db_ready_file="$sandbox_root/db.ready"
  : >"$trace_log"
  : >"$brew_log"

  if [[ "$db_initial_state" == "ready" ]]; then
    : >"$db_ready_file"
  fi

  PATH="$sandbox_root/bin:$PATH" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  DB_READY_FILE="$db_ready_file" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >/dev/null

  wait_for_file_contains "$trace_log" "stop"
  wait_for_file_contains "$trace_log" "backend"
  wait_for_file_contains "$trace_log" "frontend"

  if [[ "$expectation" == "brew-starts-db" ]]; then
    assert_file_contains "$brew_log" "services start postgresql"
  else
    assert_file_empty "$brew_log"
  fi

  rm -rf "$sandbox_root"
  trap - RETURN
  echo "PASS: $case_name"
}

run_case "starts postgres when unavailable" "not-ready" "brew-starts-db"
run_case "skips postgres when already ready" "ready" "skip-brew"

echo "All restart-all checks passed."