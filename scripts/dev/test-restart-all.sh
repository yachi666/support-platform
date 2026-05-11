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
if [[ -f "${PG_SERVER_READY_FILE:?}" ]]; then
  exit 0
fi
exit 1
EOF
  chmod +x "$sandbox_root/bin/pg_isready"

  cat >"$sandbox_root/bin/psql" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${PSQL_LOG:?}"

if [[ ! -f "${PG_SERVER_READY_FILE:?}" ]]; then
  exit 1
fi

if [[ "$*" == *"SELECT 1 FROM pg_database WHERE datname = '"* ]]; then
  if [[ -f "${DB_EXISTS_FILE:?}" ]]; then
    printf '1\n'
  fi
  exit 0
fi

printf '1\n'
EOF
  chmod +x "$sandbox_root/bin/psql"

  cat >"$sandbox_root/bin/createdb" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${CREATEDB_LOG:?}"
if [[ ! -f "${PG_SERVER_READY_FILE:?}" ]]; then
  exit 1
fi
: >"${DB_EXISTS_FILE:?}"
EOF
  chmod +x "$sandbox_root/bin/createdb"

  cat >"$sandbox_root/bin/pg_ctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${PG_CTL_LOG:?}"
if [[ "$*" == *" status"* ]]; then
  if [[ -f "${PG_SERVER_READY_FILE:?}" ]]; then
    echo "pg_ctl: server is running"
    exit 0
  fi
  echo "pg_ctl: no server running" >&2
  exit 3
fi
if [[ "$*" == *" start"* ]]; then
  : >"${PG_SERVER_READY_FILE:?}"
  exit 0
fi
exit 0
EOF
  chmod +x "$sandbox_root/bin/pg_ctl"

  cat >"$sandbox_root/bin/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "$*" >>"${BREW_LOG:?}"
if [[ "${BREW_SHOULD_FAIL:-0}" == "1" ]]; then
  echo "Bootstrap failed: 5: Input/output error" >&2
  echo "Error: Failure while executing; /bin/launchctl bootstrap gui/501 ... exited with 5." >&2
  exit 1
fi
if [[ "$*" == "services start postgresql" ]]; then
  : >"${PG_SERVER_READY_FILE:?}"
fi
EOF
  chmod +x "$sandbox_root/bin/brew"
}

run_success_case() {
  local case_name="$1"
  local server_initial_state="$2"
  local db_initial_state="$3"
  local brew_expectation="$4"
  local createdb_expectation="$5"
  local start_local_postgres="${6:-auto}"
  local sandbox_root

  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local pg_server_ready_file="$sandbox_root/pg-server.ready"
  local db_exists_file="$sandbox_root/db.exists"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local psql_log="$sandbox_root/psql.log"
  local createdb_log="$sandbox_root/createdb.log"
  local pg_ctl_log="$sandbox_root/pg-ctl.log"
  local output_log="$sandbox_root/output.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$psql_log"
  : >"$createdb_log"
  : >"$pg_ctl_log"

  mkdir -p "$sandbox_root/homebrew/var/postgresql@18"
  printf '18\n' >"$sandbox_root/homebrew/var/postgresql@18/PG_VERSION"

  if [[ "$server_initial_state" == "ready" ]]; then
    : >"$pg_server_ready_file"
  fi

  if [[ "$db_initial_state" == "exists" ]]; then
    : >"$db_exists_file"
  fi

  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  PG_SERVER_READY_FILE="$pg_server_ready_file" \
  DB_EXISTS_FILE="$db_exists_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  PSQL_LOG="$psql_log" \
  CREATEDB_LOG="$createdb_log" \
  PG_CTL_LOG="$pg_ctl_log" \
  HOMEBREW_PREFIX="$sandbox_root/homebrew" \
  START_LOCAL_POSTGRES_WITH_BREW="$start_local_postgres" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >/dev/null

  wait_for_file_contains "$trace_log" "stop"
  wait_for_file_contains "$trace_log" "backend"
  wait_for_file_contains "$trace_log" "frontend"

  if [[ "$brew_expectation" == "brew-runs" ]]; then
    assert_file_contains "$brew_log" "services start postgresql"
  else
    assert_file_empty "$brew_log"
  fi

  if [[ "$createdb_expectation" == "createdb-runs" ]]; then
    assert_file_contains "$createdb_log" "support"
  else
    assert_file_empty "$createdb_log"
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
  local pg_server_ready_file="$sandbox_root/pg-server.ready"
  local db_exists_file="$sandbox_root/db.exists"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local psql_log="$sandbox_root/psql.log"
  local createdb_log="$sandbox_root/createdb.log"
  local pg_ctl_log="$sandbox_root/pg-ctl.log"
  local output_log="$sandbox_root/output.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$psql_log"
  : >"$createdb_log"
  : >"$pg_ctl_log"

  mkdir -p "$sandbox_root/homebrew/var/postgresql@18"
  printf '18\n' >"$sandbox_root/homebrew/var/postgresql@18/PG_VERSION"

  set +e
  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  PG_SERVER_READY_FILE="$pg_server_ready_file" \
  DB_EXISTS_FILE="$db_exists_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  PSQL_LOG="$psql_log" \
  CREATEDB_LOG="$createdb_log" \
  PG_CTL_LOG="$pg_ctl_log" \
  HOMEBREW_PREFIX="$sandbox_root/homebrew" \
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

run_success_case "starts local postgres automatically on first boot" "not-ready" "missing" "brew-runs" "createdb-runs"
run_success_case "skips brew when postgres server is already ready" "ready" "exists" "skip-brew" "skip-createdb"
run_success_case "creates missing local database on first startup" "ready" "missing" "skip-brew" "createdb-runs"

brew_failure_falls_back_case() {
  local sandbox_root
  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local pg_server_ready_file="$sandbox_root/pg-server.ready"
  local db_exists_file="$sandbox_root/db.exists"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local psql_log="$sandbox_root/psql.log"
  local createdb_log="$sandbox_root/createdb.log"
  local pg_ctl_log="$sandbox_root/pg-ctl.log"
  local output_log="$sandbox_root/output.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$psql_log"
  : >"$createdb_log"
  : >"$pg_ctl_log"

  mkdir -p "$sandbox_root/homebrew/var/postgresql@18"
  printf '18\n' >"$sandbox_root/homebrew/var/postgresql@18/PG_VERSION"

  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  PG_SERVER_READY_FILE="$pg_server_ready_file" \
  DB_EXISTS_FILE="$db_exists_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  PSQL_LOG="$psql_log" \
  CREATEDB_LOG="$createdb_log" \
  PG_CTL_LOG="$pg_ctl_log" \
  HOMEBREW_PREFIX="$sandbox_root/homebrew" \
  BREW_SHOULD_FAIL="1" \
  START_LOCAL_POSTGRES_WITH_BREW="1" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >"$output_log" 2>&1

  assert_file_contains "$brew_log" "services start postgresql"
  assert_file_contains "$pg_ctl_log" "-D $sandbox_root/homebrew/var/postgresql@18 -l $sandbox_root/.dev-runtime/logs/postgresql.log start"
  wait_for_file_contains "$trace_log" "backend"
  assert_file_contains "$output_log" "Homebrew PostgreSQL service failed to start; detailed output saved to"
  if grep -F -- "launchctl bootstrap" "$output_log" >/dev/null 2>&1; then
    fail "Expected brew launchctl noise to stay out of console output"
  fi

  rm -rf "$sandbox_root"
  trap - RETURN
  echo "PASS: falls back to pg_ctl when brew startup fails"
}

brew_failure_falls_back_case

disabled_auto_start_case() {
  local sandbox_root
  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local pg_server_ready_file="$sandbox_root/pg-server.ready"
  local db_exists_file="$sandbox_root/db.exists"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local psql_log="$sandbox_root/psql.log"
  local createdb_log="$sandbox_root/createdb.log"
  local output_log="$sandbox_root/output.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$psql_log"
  : >"$createdb_log"
  rm -f "$sandbox_root/bin/pg_ctl"

  set +e
  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  PG_SERVER_READY_FILE="$pg_server_ready_file" \
  DB_EXISTS_FILE="$db_exists_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  PSQL_LOG="$psql_log" \
  CREATEDB_LOG="$createdb_log" \
  START_LOCAL_POSTGRES_WITH_BREW="0" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >"$output_log" 2>&1
  local exit_code=$?
  set -e

  assert_exit_code "$exit_code" "1"
  assert_file_contains "$output_log" "PostgreSQL server is not ready. Set START_LOCAL_POSTGRES_WITH_BREW=1 to force Homebrew startup"
  assert_file_empty "$trace_log"

  rm -rf "$sandbox_root"
  trap - RETURN
  echo "PASS: allows disabling automatic local postgres startup"
}

disabled_auto_start_case

custom_db_case() {
  local sandbox_root
  sandbox_root="$(mktemp -d)"
  trap 'rm -rf "$sandbox_root"' RETURN
  setup_fake_repo "$sandbox_root"

  local trace_log="$sandbox_root/trace.log"
  local brew_log="$sandbox_root/brew.log"
  local pg_server_ready_file="$sandbox_root/pg-server.ready"
  local db_exists_file="$sandbox_root/db.exists"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local psql_log="$sandbox_root/psql.log"
  local createdb_log="$sandbox_root/createdb.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$psql_log"
  : >"$createdb_log"
  : >"$pg_server_ready_file"
  : >"$db_exists_file"

  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  PG_SERVER_READY_FILE="$pg_server_ready_file" \
  DB_EXISTS_FILE="$db_exists_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  PSQL_LOG="$psql_log" \
  CREATEDB_LOG="$createdb_log" \
  DB_URL="jdbc:postgresql://10.20.30.40:5544/support_stage" \
  DB_USERNAME="service-user" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >/dev/null

  assert_file_contains "$pg_isready_log" "-h 10.20.30.40 -p 5544 -d postgres -U service-user"
  assert_file_contains "$psql_log" "SELECT 1 FROM pg_database WHERE datname = 'support_stage'"

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
  local pg_server_ready_file="$sandbox_root/pg-server.ready"
  local db_exists_file="$sandbox_root/db.exists"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local psql_log="$sandbox_root/psql.log"
  local createdb_log="$sandbox_root/createdb.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$psql_log"
  : >"$createdb_log"
  : >"$pg_server_ready_file"
  : >"$db_exists_file"

  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  PG_SERVER_READY_FILE="$pg_server_ready_file" \
  DB_EXISTS_FILE="$db_exists_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  PSQL_LOG="$psql_log" \
  CREATEDB_LOG="$createdb_log" \
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
  local pg_server_ready_file="$sandbox_root/pg-server.ready"
  local db_exists_file="$sandbox_root/db.exists"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local psql_log="$sandbox_root/psql.log"
  local createdb_log="$sandbox_root/createdb.log"
  local output_log="$sandbox_root/output.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$psql_log"
  : >"$createdb_log"
  rm -f "$sandbox_root/bin/pg_ctl"

  set +e
  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  PG_SERVER_READY_FILE="$pg_server_ready_file" \
  DB_EXISTS_FILE="$db_exists_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  PSQL_LOG="$psql_log" \
  CREATEDB_LOG="$createdb_log" \
  START_LOCAL_POSTGRES_WITH_BREW="1" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >"$output_log" 2>&1
  local exit_code=$?
  set -e

  assert_exit_code "$exit_code" "1"
  assert_file_contains "$output_log" "pg_ctl is unavailable, so restart-all.sh cannot fall back to direct PostgreSQL startup."
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
  local pg_server_ready_file="$sandbox_root/pg-server.ready"
  local db_exists_file="$sandbox_root/db.exists"
  local pg_isready_log="$sandbox_root/pg-isready.log"
  local psql_log="$sandbox_root/psql.log"
  local createdb_log="$sandbox_root/createdb.log"
  local output_log="$sandbox_root/output.log"
  local test_path="$sandbox_root/bin:/usr/bin:/bin"
  : >"$trace_log"
  : >"$brew_log"
  : >"$pg_isready_log"
  : >"$psql_log"
  : >"$createdb_log"
  : >"$pg_server_ready_file"
  : >"$db_exists_file"
  rm -f "$sandbox_root/bin/pg_isready"

  PATH="$test_path" \
  TRACE_LOG="$trace_log" \
  BREW_LOG="$brew_log" \
  PG_SERVER_READY_FILE="$pg_server_ready_file" \
  DB_EXISTS_FILE="$db_exists_file" \
  PG_ISREADY_LOG="$pg_isready_log" \
  PSQL_LOG="$psql_log" \
  CREATEDB_LOG="$createdb_log" \
  START_LOCAL_POSTGRES_WITH_BREW="1" \
  BACKEND_HEALTH_URL="http://127.0.0.1:8080/actuator/health" \
  FRONTEND_URL="http://127.0.0.1:5173" \
  "$sandbox_root/scripts/dev/restart-all.sh" >"$output_log" 2>&1

  assert_file_contains "$trace_log" "stop"
  assert_file_contains "$psql_log" "-d postgres"

  rm -rf "$sandbox_root"
  trap - RETURN
  echo "PASS: missing pg_isready falls back to psql"
}

missing_pg_isready_case

echo "All restart-all checks passed."
