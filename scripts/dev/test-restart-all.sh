#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/scripts/dev/restart-all.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_exit_code() {
  local actual="$1"
  local expected="$2"

  [[ "$actual" == "$expected" ]] || fail "Expected exit code $expected but got $actual"
}

assert_file_contains() {
  local file_path="$1"
  local expected="$2"

  grep -F -- "$expected" "$file_path" >/dev/null 2>&1 || fail "Expected '$expected' in $file_path"
}

assert_file_empty() {
  local file_path="$1"

  [[ ! -s "$file_path" ]] || fail "Expected $file_path to be empty"
}

wait_for_file_contains() {
  local file_path="$1"
  local expected="$2"

  for _ in {1..50}; do
    if grep -F -- "$expected" "$file_path" >/dev/null 2>&1; then
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
printf '%s\n' "$*" >>"${PG_ISREADY_LOG:?}"
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
if [[ "${BREW_SHOULD_FAIL:-0}" == "1" ]]; then
  exit 1
fi
if [[ "$*" == "services start postgresql" ]]; then
  : >"${DB_READY_FILE:?}"
fi
EOF
  chmod +x "$sandbox_root/bin/brew"
}

run_success_case() {
  local case_name="$1"
  local db_initial_state="$2"
  local expectation="$3"
  local start_local_postgres="${4:-0}"
  local sandbox_root

  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local db_ready_file="$sandbox_root/db.ready"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"

  if [[ "$db_initial_state" == "ready" ]]; then
    : >"$db_ready_file"
  fi

  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  DB_READY_FILE="$db_ready_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  START_LOCAL_POSTGRES_WITH_BREW="$start_local_postgres" \
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

run_failure_case() {
  local case_name="$1"
  local expected_message="$2"
  local sandbox_root

  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local db_ready_file="$sandbox_root/db.ready"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local output_log="$sandbox_root/output.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"

  set +e
  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  DB_READY_FILE="$db_ready_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >"$output_log" 2>&1
  local exit_code=$?
  set -e

  assert_exit_code "$exit_code" "1"
  assert_file_contains "$output_log" "$expected_message"
  assert_file_empty "$trace_log"

  rm -rf "$sandbox_root"
  trap - RETURN
  echo "PASS: $case_name"
}

run_success_case "starts postgres only when brew opt-in is enabled" "not-ready" "brew-starts-db" "1"
run_success_case "skips postgres when already ready" "ready" "skip-brew"
run_failure_case "requires brew opt-in before mutating local postgres service state" "Set START_LOCAL_POSTGRES_WITH_BREW=1 to allow restart-all.sh to start Homebrew PostgreSQL automatically."

custom_db_case() {
  local sandbox_root
  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local db_ready_file="$sandbox_root/db.ready"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$db_ready_file"

  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  DB_READY_FILE="$db_ready_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  DB_URL="jdbc:postgresql://10.20.30.40:5544/support_stage" \
  DB_USERNAME="service-user" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >/dev/null

  assert_file_contains "$pg_isready_log" "-h 10.20.30.40 -p 5544 -d support_stage -U service-user"

  rm -rf "$sandbox_root"
  trap - RETURN
  echo "PASS: derives postgres readiness target from DB_URL"
}

custom_db_case

default_username_case() {
  local sandbox_root
  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"

  cat >"$sandbox_root/bin/id" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == "-un" ]]; then
  echo portable-user
  exit 0
fi
/usr/bin/id "$@"
EOF
  chmod +x "$sandbox_root/bin/id"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local db_ready_file="$sandbox_root/db.ready"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$db_ready_file"

  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  DB_READY_FILE="$db_ready_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >/dev/null

  assert_file_contains "$pg_isready_log" "-U portable-user"

  rm -rf "$sandbox_root"
  trap - RETURN
  echo "PASS: defaults postgres readiness username to current user"
}

default_username_case

missing_brew_case() {
  local sandbox_root
  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"
  rm -f "$sandbox_root/bin/brew"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local db_ready_file="$sandbox_root/db.ready"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local output_log="$sandbox_root/output.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"

  set +e
  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  DB_READY_FILE="$db_ready_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  START_LOCAL_POSTGRES_WITH_BREW="1" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >"$output_log" 2>&1
  local exit_code=$?
  set -e

  assert_exit_code "$exit_code" "1"
  assert_file_contains "$output_log" "Homebrew is unavailable, so restart-all.sh cannot start PostgreSQL automatically."
  assert_file_empty "$trace_log"

  rm -rf "$sandbox_root"
  trap - RETURN
  echo "PASS: missing brew fails clearly"
}

missing_brew_case

missing_pg_isready_case() {
  local sandbox_root
  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"
  rm -f "$sandbox_root/bin/pg_isready"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local db_ready_file="$sandbox_root/db.ready"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local output_log="$sandbox_root/output.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"

  set +e
  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  DB_READY_FILE="$db_ready_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  START_LOCAL_POSTGRES_WITH_BREW="1" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >"$output_log" 2>&1
  local exit_code=$?
  set -e

  assert_exit_code "$exit_code" "1"
  assert_file_contains "$output_log" "pg_isready is required to verify PostgreSQL readiness before restarting services."
  assert_file_empty "$trace_log"

  rm -rf "$sandbox_root"
  trap - RETURN
  echo "PASS: missing pg_isready fails clearly"
}

missing_pg_isready_case

echo "All restart-all checks passed."
